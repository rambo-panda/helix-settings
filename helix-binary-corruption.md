# Helix Editor Critical Defect: Silent Binary File Corruption

## Phenomenon

When opening and saving a PDF (or any binary file) in Helix, the file gets silently corrupted.
The file size increases by ~41% due to UTF-8 replacement of binary bytes.

### Concrete Example

- `skills.bak.pdf` (original): 789.9 KB
- `skills.pdf` (saved by Helix): 1.1 MB (+41.2%)
- 170,823 bytes in FlateDecode compressed streams were replaced with U+FFFD (`ef bf bd`)

### Before (original):
```
stream\n78 9c 85 53 4d 48 54 51 14 fe ee 7d 6f 66 1c 71 ca ...
```

### After (Helix saved):
```
stream\n78 ef bf bd 85 53 4d 48 54 51 14 ef bf bd ef bf bd 7d ...
```
Each non-UTF-8 byte (0x80-0xFF range) in the zlib stream was replaced by 3-byte U+FFFD.

## Root Cause

Helix uses the `ropey` crate as its text backend, which enforces **all content must be valid UTF-8**.
When loading a file, any byte that is not valid UTF-8 is replaced with U+FFFD (Unicode Replacement Character).
On save, the corrupted content is written back — the original bytes are permanently lost.

This is a **design decision**, not a bug. The Helix maintainer (@pascalkuthe) explicitly stated:

> "There is no way to manually set the encoding while reading a file with helix — it's always auto detected.
> Once the file has been read to memory it's always converted to UTF-8, so at that point the encoding
> information is already lost."
>
> "No, there is no way to set the encoding manually and there are no plans to add that."

## What's Missing in Helix

- No binary mode / raw mode
- No per-filetype encoding setting
- No `++binary` or `++enc=latin1` option (unlike Vim)
- No BufRead / autocmd hooks to preprocess files
- No warning when opening binary files

## Related Discussion

- GitHub Discussion: https://github.com/helix-editor/helix/discussions/7580
  - Originally about windows-1252 encoding detection failure on Windows
  - Same mechanism: non-UTF-8 bytes replaced by U+FFFD on load, corrupted content saved back
  - Maintainer confirmed no plans to add manual encoding control

## Verdict

**Helix silently destroys binary files on save. This is a critical design flaw, not a warning.**
The maintainer has explicitly stated there are no plans to fix it.

Use Vim instead — it has `:set binary`, `++enc`, `++binary` and autocmd hooks for proper binary file handling.
