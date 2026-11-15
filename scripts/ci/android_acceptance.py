#!/usr/bin/env python3
"""Bind ARM64 human QA to GitHub's trusted review history and exact APK SHA.

The approval comment is ANDROID_ACCEPTANCE_V1 on its own line followed by one
JSON object. Reviewer allowlist comes from protected repository configuration,
never from a PR artifact or the comment itself. Publisher re-fetches reviews.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parent))

RESULTS = ('install','solo','jewel','touch','lifecycle','audio','update')
ENVIRONMENT = 'android-device-acceptance'


def validate_reviews(reviews, manifest, run_id, trusted_reviewers):
    if not trusted_reviewers or not isinstance(run_id,int) or run_id <= 0:
        raise ValueError('Trusted reviewers and positive run ID required')
    relevant = [review for review in reviews if any(e.get('name')==ENVIRONMENT for e in review.get('environments',[]))]
    # Newest review for this environment wins; a later rejection invalidates a
    # prior approval. GitHub returns chronological review history.
    if not relevant:
        raise ValueError('No ARM64 environment approval')
    review = relevant[-1]
    user = review.get('user',{})
    if review.get('state') != 'approved' or user.get('login') not in trusted_reviewers or not isinstance(user.get('id'),int):
        raise ValueError('ARM64 approval is not from a trusted reviewer')
    comment = review.get('comment','')
    if not comment.startswith('ANDROID_ACCEPTANCE_V1\n'):
        raise ValueError('ARM64 structured QA report missing')
    data = json.loads(comment.split('\n',1)[1])
    expected = dict(run_id=run_id,commit=manifest['commit'],apk_sha256=manifest['sha256'],version=manifest['version'],abi='arm64-v8a')
    if any(data.get(k)!=v for k,v in expected.items()):
        raise ValueError('ARM64 approval does not identify this run/APK')
    if (manifest.get('arm64_acceptance')!='manual_gate_required'
            or not re.fullmatch('[0-9a-f]{64}',data['apk_sha256'])
            or not re.fullmatch('[0-9a-f]{40}',data['commit'])):
        raise ValueError('Invalid ARM64 artifact identity')
    if any(data.get('results',{}).get(k)!='passed' for k in RESULTS):
        raise ValueError('ARM64 QA results incomplete/failed')
    if not isinstance(data.get('api'),int) or data['api']<24:
        raise ValueError('ARM64 device API invalid')
    for key in ('device','gpu'):
        if not isinstance(data.get(key),str) or not data[key].strip() or '\n' in data[key]:
            raise ValueError('ARM64 device metadata missing')
    evidence = urlsplit(data.get('evidence_url',''))
    if evidence.scheme!='https' or not evidence.netloc or evidence.username or evidence.password:
        raise ValueError('Durable HTTPS QA evidence required')
    return dict(data,schema=1,environment=ENVIRONMENT,reviewer=user['login'],reviewer_id=user['id'],source='github-actions-review-history')


def fetch_acceptance(api, manifest, run_id, trusted_reviewers):
    run = api.request('GET',f'/actions/runs/{run_id}')
    if (not run or run.get('event')!='push' or run.get('head_branch')!='main'
            or run.get('head_sha')!=manifest['commit']):
        raise ValueError('Acceptance run is not the tested main push')
    reviews = api.request('GET',f'/actions/runs/{run_id}/approvals')
    if not isinstance(reviews,list):
        raise ValueError('Review history unavailable')
    return validate_reviews(reviews,manifest,run_id,trusted_reviewers)


def main():
    from publish import GitHub
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=Path('android-acceptance.json'))
    args=parser.parse_args()
    manifest=json.loads(args.manifest.read_text())
    result=fetch_acceptance(GitHub(os.environ['GITHUB_REPOSITORY'],os.environ['GH_TOKEN']),manifest,
                            int(os.environ['GITHUB_RUN_ID']),set(filter(None,os.environ.get('ANDROID_TRUSTED_REVIEWERS','').split(','))))
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n')


if __name__=='__main__':
    main()
