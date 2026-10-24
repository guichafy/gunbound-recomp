extends RefCounted
## Delay unit of the prototype: the OpenBound costs (DelayPresets, Item cost,
## AttackDelay/ItemDelay attributes) divided by SCALE (MAGE_0_4.md, ITEMS_0_13.md).
## Catalogs keep the original cost; this is the only conversion.

const SCALE := 7.5

## Original cost, reduced and truncated like the C# (ItemDelay/AttackDelay), in turn units.
static func from_original(cost: int, reduction: int = 0) -> float:
	return int(cost * (1.0 - reduction / 100.0)) / SCALE
