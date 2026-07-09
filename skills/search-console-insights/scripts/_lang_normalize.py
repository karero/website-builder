"""Shared language normalization for keyword matching (gsc_query, bing_query).

German searchers type both umlaut and ASCII forms ("münchen" and "muenchen",
"fußball" and "fussball") and GSC/Bing report them as DISTINCT query strings —
matching on .lower() alone reports false "no impressions yet" for whichever
variant the keyword list didn't happen to use. Fold both sides before matching.

str.casefold() already maps ß→ss; the umlaut→digraph mapping is German
orthography (ä→ae, ö→oe, ü→ue), applied after casefold.
"""

_FOLD = str.maketrans({"ä": "ae", "ö": "oe", "ü": "ue"})


def fold(s: str) -> str:
    """Casefold + German umlaut/ß folding, for match comparisons only."""
    return s.casefold().translate(_FOLD)
