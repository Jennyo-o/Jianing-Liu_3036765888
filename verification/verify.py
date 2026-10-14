"""
Internal verification script (Python).

Computes the same quantities as the Stata .do files in ../code/ so we can
cross-check correctness and fill in Section 4 of the report without a Stata
installation. This is NOT part of the Stata submission.

Usage:  python3 verification/verify.py    (run from repo root)
"""
import numpy as np
import pandas as pd

DATA = "01_DID/data/public.csv"

df = pd.read_csv(DATA)
df.columns = [c.lower() for c in df.columns]  # CSV headers are uppercase

# ----------------------------------------------------------------------------
# Derived variables (mirror of code/01_setup.do)
# ----------------------------------------------------------------------------
# Full-time-equivalent employment = managers + full-time + 0.5 * part-time
df["fte1"] = df["nmgrs"] + df["empft"] + 0.5 * df["emppt"]
df["fte2"] = df["nmgrs2"] + df["empft2"] + 0.5 * df["emppt2"]

# Wave-2 employment accounting: permanent closures (status2==3) -> 0;
# temporary closures / renovation / refused (status2 in [0,2,4,5]) -> missing.
df.loc[df["status2"] == 3, "fte2"] = 0.0
df.loc[df["status2"].isin([0, 2, 4, 5]), "fte2"] = np.nan

# Percentage full-time (fraction of non-managerial workers who are full-time).
# NOTE: matches the paper's standard error (1.3) but not its level (32.8);
# see the report, Section 4 — the public.csv full-time/part-time split differs
# slightly from the original survey data.
df["pctft1"] = df["empft"] / (df["empft"] + df["emppt"])
df["pctft2"] = df["empft2"] / (df["empft2"] + df["emppt2"])

# Price of a full meal = medium soda + small fries + entree
df["meal1"] = df["psoda"] + df["pfry"] + df["pentree"]
df["meal2"] = df["psoda2"] + df["pfry2"] + df["pentree2"]

# Wage indicators (0/1)
df["w425_1"] = (df["wage_st"] == 4.25).astype(float)
df["w425_2"] = (df["wage_st2"] == 4.25).astype(float)
df["w505_2"] = (df["wage_st2"] == 5.05).astype(float)

# Recruiting bonus (wave 1) / special program (wave 2)
df["bonus1"] = df["bonus"].astype(float)
df["bonus2"] = df["special2"].astype(float)

# Wage gap (GAP): proportional increase to reach $5.05
df["gap"] = 0.0
mask = (df["state"] == 1) & (df["wage_st"] < 5.05) & df["wage_st"].notna()
df.loc[mask, "gap"] = (5.05 - df.loc[mask, "wage_st"]) / df.loc[mask, "wage_st"]

# Change in FTE employment
df["dfte"] = df["fte2"] - df["fte1"]

# Chain dummies
for c in [1, 2, 3, 4]:
    df[f"chain{c}"] = (df["chain"] == c).astype(float)


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
def group_stats(df, col):
    """Return (NJ mean/se/n, PA mean/se/n, Welch t) for a column."""
    nj = df.loc[df["state"] == 1, col].dropna()
    pa = df.loc[df["state"] == 0, col].dropna()
    m1, s1, n1 = nj.mean(), nj.std(ddof=1), len(nj)
    m2, s2, n2 = pa.mean(), pa.std(ddof=1), len(pa)
    se1, se2 = s1 / np.sqrt(n1), s2 / np.sqrt(n2)
    se = np.sqrt(se1**2 + se2**2)
    t = (m1 - m2) / se if se > 0 else np.nan
    return m1, se1, n1, m2, se2, n2, t


def print_panel(title, rows):
    print(f"\n{title}")
    print(f"  {'Variable':<26} {'NJ':>14} {'PA':>14} {'t':>7}")
    print("  " + "-" * 63)
    for name, col, kind in rows:
        m1, se1, n1, m2, se2, n2, t = group_stats(df, col)
        scale = 100 if kind == "share" else 1
        print(
            f"  {name:<26} {m1*scale:7.2f} ({se1*scale:5.2f}) "
            f"{m2*scale:7.2f} ({se2*scale:5.2f}) {t:7.2f}"
        )


# ----------------------------------------------------------------------------
# Table 2
# ----------------------------------------------------------------------------
print("=" * 78)
print("TABLE 2 - MEANS OF KEY VARIABLES BY STATE  (NJ, PA)")
print("=" * 78)

print_panel("Panel 1. Distribution of store types (percent)", [
    ("Burger King", "chain1", "share"),
    ("KFC", "chain2", "share"),
    ("Roy Rogers", "chain3", "share"),
    ("Wendy's", "chain4", "share"),
    ("Company-owned", "co_owned", "share"),
])

print_panel("Panel 2. Means in wave 1", [
    ("FTE employment", "fte1", "level"),
    ("% full-time employees", "pctft1", "share"),
    ("Starting wage", "wage_st", "level"),
    ("Wage = $4.25 (%)", "w425_1", "share"),
    ("Price of full meal", "meal1", "level"),
    ("Hours open (weekday)", "hrsopen", "level"),
    ("Recruiting bonus", "bonus1", "share"),
])

print_panel("Panel 3. Means in wave 2", [
    ("FTE employment", "fte2", "level"),
    ("% full-time employees", "pctft2", "share"),
    ("Starting wage", "wage_st2", "level"),
    ("Wage = $4.25 (%)", "w425_2", "share"),
    ("Wage = $5.05 (%)", "w505_2", "share"),
    ("Price of full meal", "meal2", "level"),
    ("Hours open (weekday)", "hrsopen2", "level"),
    ("Recruiting bonus", "bonus2", "share"),
])

print("\nSample counts by state:", df.groupby("state").size().to_dict())
print("status2 counts:", df["status2"].value_counts(dropna=False).sort_index().to_dict())
