Checked with Luke, the shipments tab is non-cmp
The report is using invoices

The visual is filtered to:

Review sproc 1 for:
   confirm invoice is used.

```text
BusinessStream2 is FIN or MFG
```

and **BusinessStream2** is defined as:

```m
if [BUS_STREAM] = "CMP-FIN" then 1
else if [BUS_STREAM] = "CMP-MFG" then 2
else [BUS_STREAM]
```

which means:

| BUS\_STREAM | BusinessStream2 |
| ----------- | --------------- |
| CMP-FIN     | 1               |
| CMP-MFG     | 2               |
| FIN         | FIN             |
| MFG         | MFG             |
| OTHER       | OTHER           |

Now look at the filter:

```text
BusinessStream2 is FIN or MFG
```

That explicitly excludes:

```text
1
2
OTHER
```

which means:

```text
CMP-FIN
CMP-MFG
```

are being filtered out.

So the "Monthly Goals" visual you're investigating appears to be deliberately showing only:

```text
FIN
MFG
```

and not the CMP streams.

***

### What I think happened

The developer likely needed two different reporting views:

#### View A

```text
CMP-FIN
CMP-MFG
```

used in a CMP-specific visual.

#### View B

```text
FIN
MFG
```

used in the manager overview.

Instead of creating separate dimensions or a mapping table, they created:

```m
BusinessStream2
```

and then used visual-level filters.

It works, but it's not very transparent.

***

### What I'd do in Scratch

Create a simple diagnostic matrix:

```text
BUS_STREAM
BusinessStream2
Shipped Amount
```

Expected result:

| BUS\_STREAM | BusinessStream2 |
| ----------- | --------------- |
| CMP-FIN     | 1               |
| CMP-MFG     | 2               |
| FIN         | FIN             |
| MFG         | MFG             |
| OTHER       | OTHER           |

That will confirm exactly how the current report is partitioning the data.

***

### More importantly

This reduces my concern about duplication.

Originally I was worried that:

```text
CMP-FIN + FIN
```

or

```text
CMP-MFG + MFG
```

might be getting aggregated together.

But now it looks like the business logic may actually be:

* Some visuals use CMP streams.
* Some visuals use non-CMP streams.
* `BusinessStream2` is acting as a categorization device.

So before changing anything, I'd verify:

```DAX
Rows by BUS_STREAM
Amount by BUS_STREAM
```

to make sure the same shipment isn't appearing once as `CMP-FIN` and again as `FIN`.

That's the remaining risk I'd want to eliminate before moving forward with the forecast redesign.

To me, your biggest win today is that you're starting to understand **why** `BusinessStream2` exists. It may not be a mistake at all—it may be a workaround to support two different reporting perspectives from the same shipment source.
