-- Package: adam
-- File:    src/pattern.ads
-- Summary: MUMPS Pattern Matching specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

package Pattern is

   -- Match a string against a MUMPS pattern
   -- Pattern format: count code [count code ...]
   -- e.g., "3A" = exactly 3 letters, "1A1N1A" = letter digit letter
   -- Pattern codes: A=alpha, N=numeric, E=everything, U=uppercase, L=lowercase,
   --                P=punctuation, C=control
   -- Count can be: N (exact), N.M (range), .M (0 to M), N. (N or more)
   function Match (Str : String; Pat : String) return Boolean;

end Pattern;
