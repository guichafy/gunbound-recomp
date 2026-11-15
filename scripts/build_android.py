#!/usr/bin/env python3
"""Build a test Android APK by default; distribution signing is explicit."""
from ci.android_package import main

if __name__ == '__main__':
    main()
