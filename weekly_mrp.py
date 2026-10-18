"""Weekly MRP planning logic aligned to the A1/A2 amendments.

The model intentionally avoids a 7-day "from today" window and removes any
past-due bucket semantics. Instead, the horizon is built directly from the
requested first bucket date and the supplied Visual MRP beginning inventory
position.

The bucket semantics are:
- Bucket 1 beginning balance = input beginning inventory position.
- Bucket n beginning balance = previous bucket beginning balance + previous
  bucket supply - previous bucket gross requirements.
- There is no past-due bucket or past-due flag.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import Iterable, List, Sequence


@dataclass(frozen=True)
class WeeklyBucket:
    """Single weekly bucket in the planning horizon."""

    bucket_number: int
    start_date: date
    end_date: date
    beginning_balance: float
    supply: float
    gross_requirements: float
    ending_balance: float

    def to_dict(self) -> dict:
        return {
            "bucket_number": self.bucket_number,
            "start_date": self.start_date.isoformat(),
            "end_date": self.end_date.isoformat(),
            "beginning_balance": self.beginning_balance,
            "supply": self.supply,
            "gross_requirements": self.gross_requirements,
            "ending_balance": self.ending_balance,
        }


def _coerce_float(value: float | int | str) -> float:
    return float(value)


def compute_weekly_mrp(
    start_date: date,
    bucket_count: int,
    beginning_inventory_position: float | int | str,
    supply_by_bucket: Sequence[float | int | str],
    gross_requirements_by_bucket: Sequence[float | int | str],
) -> List[WeeklyBucket]:
    """Compute weekly MRP buckets using the A1/A2 semantics.

    A2 behavior encoded here:
    - bucket 1 beginning balance comes from the Visual MRP beginning inventory
      position supplied as input
    - bucket 2+ beginning balance is prior beginning balance + prior supply -
      prior gross requirements
    - no past-due bucket is created
    - there is no fixed 7-day window relative to today
    """
    if bucket_count < 0:
        raise ValueError("bucket_count must be >= 0")
    if bucket_count == 0:
        return []

    if len(supply_by_bucket) < bucket_count:
        raise ValueError("supply_by_bucket must cover all requested buckets")
    if len(gross_requirements_by_bucket) < bucket_count:
        raise ValueError(
            "gross_requirements_by_bucket must cover all requested buckets"
        )

    bucket_1_beginning = _coerce_float(beginning_inventory_position)
    buckets: List[WeeklyBucket] = []
    prior_beginning = bucket_1_beginning
    prior_supply = 0.0
    prior_gross_requirements = 0.0

    for idx in range(bucket_count):
        bucket_number = idx + 1
        bucket_start = start_date + timedelta(weeks=idx)
        bucket_end = bucket_start + timedelta(days=6)

        supply = _coerce_float(supply_by_bucket[idx])
        gross_requirements = _coerce_float(gross_requirements_by_bucket[idx])

        if bucket_number == 1:
            beginning_balance = bucket_1_beginning
        else:
            beginning_balance = (
                prior_beginning + prior_supply - prior_gross_requirements
            )

        ending_balance = beginning_balance + supply - gross_requirements

        buckets.append(
            WeeklyBucket(
                bucket_number=bucket_number,
                start_date=bucket_start,
                end_date=bucket_end,
                beginning_balance=beginning_balance,
                supply=supply,
                gross_requirements=gross_requirements,
                ending_balance=ending_balance,
            )
        )

        prior_beginning = beginning_balance
        prior_supply = supply
        prior_gross_requirements = gross_requirements

    return buckets


def build_weekly_mrp(
    start_date: date,
    bucket_count: int,
    beginning_inventory_position: float | int | str,
    supply_by_bucket: Sequence[float | int | str],
    gross_requirements_by_bucket: Sequence[float | int | str],
) -> List[WeeklyBucket]:
    """Backward-compatible alias for the weekly MRP builder."""
    return compute_weekly_mrp(
        start_date=start_date,
        bucket_count=bucket_count,
        beginning_inventory_position=beginning_inventory_position,
        supply_by_bucket=supply_by_bucket,
        gross_requirements_by_bucket=gross_requirements_by_bucket,
    )


def weekly_mrp(
    start_date: date,
    bucket_count: int,
    beginning_inventory_position: float | int | str,
    supply_by_bucket: Sequence[float | int | str],
    gross_requirements_by_bucket: Sequence[float | int | str],
) -> List[dict]:
    """Convenience wrapper returning dictionaries for downstream callers."""
    return [bucket.to_dict() for bucket in compute_weekly_mrp(
        start_date=start_date,
        bucket_count=bucket_count,
        beginning_inventory_position=beginning_inventory_position,
        supply_by_bucket=supply_by_bucket,
        gross_requirements_by_bucket=gross_requirements_by_bucket,
    )]


def render_weekly_mrp_rows(bucket_rows: Iterable[WeeklyBucket]) -> List[dict]:
    return [bucket.to_dict() for bucket in bucket_rows]


if __name__ == "__main__":
    first_bucket = date(2026, 10, 19)
    rows = compute_weekly_mrp(
        start_date=first_bucket,
        bucket_count=4,
        beginning_inventory_position=100,
        supply_by_bucket=[15, 10, 5, 20],
        gross_requirements_by_bucket=[40, 35, 25, 20],
    )
    for row in rows:
        print(row.to_dict())
