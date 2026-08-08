-- The eight-swatch set failed the categorical colour checks: at constant
-- lightness, amber and olive were indistinguishable under deuteranopia, and
-- teal and cyan under normal vision. DESIGN.md now carries six swatches that
-- alternate lightness as well as hue. The old default is no longer one of them.

alter table public.cards
  alter column color set default '#494ECF';
