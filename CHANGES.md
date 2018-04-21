# History of Changes to Flooph

## v0.2 — 2018-Apr-20

* Unless `$DEBUG` is set, Flooph will no longer rescue parse errors and output debug information. On a parse failure `Parslet::ParseFailed` is raised.

## v0.1.3 — 2018-Apr-14

* Workaround [parslet bug #193](https://github.com/kschiess/parslet/issues/193)

## v0.1.1 — 2018-Apr-13

* Allow CRLF for newlines in variable assignments (silly HTML textarea)

## v0.1 — 2018-Apr-8

* Initial Release