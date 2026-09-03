"""Shared language normalization for keyword matching (gsc_query, bing_query).

German searchers type both umlaut and ASCII forms ("münchen" and "muenchen",
"fußball" and "fussball") and GSC/Bing report them as DISTINCT query strings —
matching on .lower() alone reports false "no impressions yet" for whichever
variant the keyword list didn't happen to use. Fold both sides before matching.

str.casefold() already maps ß→ss; the umlaut→digraph mapping is German
orthography (ä→ae, ö→oe, ü→ue), applied after casefold.
"""

import unicodedata

_FOLD = str.maketrans({"ä": "ae", "ö": "oe", "ü": "ue"})


def fold(s: str) -> str:
    """Casefold + German umlaut/ß folding, for match comparisons only.

    NFC first: a decomposed umlaut (u + combining diaeresis, e.g. pasted from a
    macOS filename) survives casefold as-is and would miss the translate table.
    Note the deliberate merge: ß→ss folding equates genuinely distinct words
    (Maße/Masse, Buße/Busse) — acceptable for search-intent matching, where
    searchers type both spellings interchangeably anyway.
    """
    return unicodedata.normalize("NFC", s).casefold().translate(_FOLD)


def match_rank(folded_query: str, tokens: list) -> tuple:
    """Sort key for the queries that matched one target keyword: lower is a
    better "best match". Pair it with -impressions as the tie-breaker.

    Ranking by impressions alone let an 8-impression, fifteen-word query
    ("german ai tech industry meetups munich berlin hamburg ...") beat the
    exact phrase "ai events munich" (3 impressions) as the reported position
    for the keyword -- and the history then tracked that long-tail query, for
    two different keywords at once (seen live, 2026-09-03). The keyword IS the
    question the owner asked, so:
      1. the exact phrase, when Google/Bing reported it, is the answer;
      2. otherwise the query with the fewest extra words is closest to that
         intent ("ai events in munich" over a sentence that merely contains
         the tokens);
      3. only then does volume decide.
    """
    words = folded_query.split()
    exact = words == tokens
    return (0 if exact else 1, max(len(words) - len(tokens), 0))
