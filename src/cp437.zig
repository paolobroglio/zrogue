const std = @import("std");
const testing = std.testing;
const rl = @import("raylib");

const tilesPerRows: f16 = 16.0;

// Define the CodepageMap struct first
const CodepageMap = struct {
    char: u21, // Unicode scalar value for the character
    cp_index: u8, // The Codepage 437 index for that character
};

// Complete the Codepage437Map
const Codepage437Map = [_]CodepageMap{
    // --- Control Characters (CP_INDEX 0-31) ---
    // Note: Many of these are non-printable or have special rendering rules.
    // Unicode mappings for control characters can be complex and context-dependent.
    // These mappings are typical, but actual display might vary.
    .{ .char = '\x00', .cp_index = 0 },  // NUL (Null)
    .{ .char = '☺', .cp_index = 1 },   // Smiling Face
    .{ .char = '☻', .cp_index = 2 },   // Black Smiling Face
    .{ .char = '♥', .cp_index = 3 },   // Heart
    .{ .char = '♦', .cp_index = 4 },   // Diamond
    .{ .char = '♣', .cp_index = 5 },   // Club
    .{ .char = '♠', .cp_index = 6 },   // Spade
    .{ .char = '•', .cp_index = 7 },   // Bullet
    .{ .char = '◘', .cp_index = 8 },   // Inverse Bullet
    .{ .char = '○', .cp_index = 9 },   // White Circle
    .{ .char = '◙', .cp_index = 10 },  // Inverse White Circle
    .{ .char = '♂', .cp_index = 11 },  // Male Sign
    .{ .char = '♀', .cp_index = 12 },  // Female Sign
    .{ .char = '♪', .cp_index = 13 },  // Eighth Note
    .{ .char = '♫', .cp_index = 14 },  // Paired Eighth Notes
    .{ .char = '☼', .cp_index = 15 },  // White Sun with Rays
    .{ .char = '►', .cp_index = 16 },  // Black Right-Pointing Triangle
    .{ .char = '◄', .cp_index = 17 },  // Black Left-Pointing Triangle
    .{ .char = '↕', .cp_index = 18 },  // Up Down Arrow
    .{ .char = '‼', .cp_index = 19 },  // Double Exclamation Mark
    .{ .char = '¶', .cp_index = 20 },  // Pilcrow Sign (Paragraph Mark)
    .{ .char = '§', .cp_index = 21 },  // Section Sign
    .{ .char = '▬', .cp_index = 22 },  // Black Rectangle (often thin horizontal bar)
    .{ .char = '↨', .cp_index = 23 },  // Up Down Arrow with Base
    .{ .char = '↑', .cp_index = 24 },  // Upwards Arrow
    .{ .char = '↓', .cp_index = 25 },  // Downwards Arrow
    .{ .char = '→', .cp_index = 26 },  // Rightwards Arrow
    .{ .char = '←', .cp_index = 27 },  // Leftwards Arrow
    .{ .char = '∟', .cp_index = 28 },  // Right Angle
    .{ .char = '↔', .cp_index = 29 },  // Left Right Arrow
    .{ .char = '▲', .cp_index = 30 },  // Black Up-Pointing Triangle
    .{ .char = '▼', .cp_index = 31 },  // Black Down-Pointing Triangle

    // --- ASCII Characters (CP_INDEX 32-127) ---
    .{ .char = ' ', .cp_index = 32 },  // Space
    .{ .char = '!', .cp_index = 33 },
    .{ .char = '"', .cp_index = 34 },
    .{ .char = '#', .cp_index = 35 },
    .{ .char = '$', .cp_index = 36 },
    .{ .char = '%', .cp_index = 37 },
    .{ .char = '&', .cp_index = 38 },
    .{ .char = '\'', .cp_index = 39 },
    .{ .char = '(', .cp_index = 40 },
    .{ .char = ')', .cp_index = 41 },
    .{ .char = '*', .cp_index = 42 },
    .{ .char = '+', .cp_index = 43 },
    .{ .char = ',', .cp_index = 44 },
    .{ .char = '-', .cp_index = 45 },
    .{ .char = '.', .cp_index = 46 },
    .{ .char = '/', .cp_index = 47 },
    .{ .char = '0', .cp_index = 48 },
    .{ .char = '1', .cp_index = 49 },
    .{ .char = '2', .cp_index = 50 },
    .{ .char = '3', .cp_index = 51 },
    .{ .char = '4', .cp_index = 52 },
    .{ .char = '5', .cp_index = 53 },
    .{ .char = '6', .cp_index = 54 },
    .{ .char = '7', .cp_index = 55 },
    .{ .char = '8', .cp_index = 56 },
    .{ .char = '9', .cp_index = 57 },
    .{ .char = ':', .cp_index = 58 },
    .{ .char = ';', .cp_index = 59 },
    .{ .char = '<', .cp_index = 60 },
    .{ .char = '=', .cp_index = 61 },
    .{ .char = '>', .cp_index = 62 },
    .{ .char = '?', .cp_index = 63 },
    .{ .char = '@', .cp_index = 64 },
    .{ .char = 'A', .cp_index = 65 },
    .{ .char = 'B', .cp_index = 66 },
    .{ .char = 'C', .cp_index = 67 },
    .{ .char = 'D', .cp_index = 68 },
    .{ .char = 'E', .cp_index = 69 },
    .{ .char = 'F', .cp_index = 70 },
    .{ .char = 'G', .cp_index = 71 },
    .{ .char = 'H', .cp_index = 72 },
    .{ .char = 'I', .cp_index = 73 },
    .{ .char = 'J', .cp_index = 74 },
    .{ .char = 'K', .cp_index = 75 },
    .{ .char = 'L', .cp_index = 76 },
    .{ .char = 'M', .cp_index = 77 },
    .{ .char = 'N', .cp_index = 78 },
    .{ .char = 'O', .cp_index = 79 },
    .{ .char = 'P', .cp_index = 80 },
    .{ .char = 'Q', .cp_index = 81 },
    .{ .char = 'R', .cp_index = 82 },
    .{ .char = 'S', .cp_index = 83 },
    .{ .char = 'T', .cp_index = 84 },
    .{ .char = 'U', .cp_index = 85 },
    .{ .char = 'V', .cp_index = 86 },
    .{ .char = 'W', .cp_index = 87 },
    .{ .char = 'X', .cp_index = 88 },
    .{ .char = 'Y', .cp_index = 89 },
    .{ .char = 'Z', .cp_index = 90 },
    .{ .char = '[', .cp_index = 91 },
    .{ .char = '\\', .cp_index = 92 },
    .{ .char = ']', .cp_index = 93 },
    .{ .char = '^', .cp_index = 94 },
    .{ .char = '_', .cp_index = 95 },
    .{ .char = '`', .cp_index = 96 },
    .{ .char = 'a', .cp_index = 97 },
    .{ .char = 'b', .cp_index = 98 },
    .{ .char = 'c', .cp_index = 99 },
    .{ .char = 'd', .cp_index = 100 },
    .{ .char = 'e', .cp_index = 101 },
    .{ .char = 'f', .cp_index = 102 },
    .{ .char = 'g', .cp_index = 103 },
    .{ .char = 'h', .cp_index = 104 },
    .{ .char = 'i', .cp_index = 105 },
    .{ .char = 'j', .cp_index = 106 },
    .{ .char = 'k', .cp_index = 107 },
    .{ .char = 'l', .cp_index = 108 },
    .{ .char = 'm', .cp_index = 109 },
    .{ .char = 'n', .cp_index = 110 },
    .{ .char = 'o', .cp_index = 111 },
    .{ .char = 'p', .cp_index = 112 },
    .{ .char = 'q', .cp_index = 113 },
    .{ .char = 'r', .cp_index = 114 },
    .{ .char = 's', .cp_index = 115 },
    .{ .char = 't', .cp_index = 116 },
    .{ .char = 'u', .cp_index = 117 },
    .{ .char = 'v', .cp_index = 118 },
    .{ .char = 'w', .cp_index = 119 },
    .{ .char = 'x', .cp_index = 120 },
    .{ .char = 'y', .cp_index = 121 },
    .{ .char = 'z', .cp_index = 122 },
    .{ .char = '{', .cp_index = 123 },
    .{ .char = '|', .cp_index = 124 },
    .{ .char = '}', .cp_index = 125 },
    .{ .char = '~', .cp_index = 126 },
    .{ .char = '⌂', .cp_index = 127 },  // House

    // --- Extended ASCII / IBM PC Graphic Characters (CP_INDEX 128-255) ---
    .{ .char = 'Ç', .cp_index = 128 },
    .{ .char = 'ü', .cp_index = 129 },
    .{ .char = 'é', .cp_index = 130 },
    .{ .char = 'â', .cp_index = 131 },
    .{ .char = 'ä', .cp_index = 132 },
    .{ .char = 'à', .cp_index = 133 },
    .{ .char = 'å', .cp_index = 134 },
    .{ .char = 'ç', .cp_index = 135 },
    .{ .char = 'ê', .cp_index = 136 },
    .{ .char = 'ë', .cp_index = 137 },
    .{ .char = 'è', .cp_index = 138 },
    .{ .char = 'ï', .cp_index = 139 },
    .{ .char = 'î', .cp_index = 140 },
    .{ .char = 'ì', .cp_index = 141 },
    .{ .char = 'Ä', .cp_index = 142 },
    .{ .char = 'Å', .cp_index = 143 },
    .{ .char = 'É', .cp_index = 144 },
    .{ .char = 'æ', .cp_index = 145 },
    .{ .char = 'Æ', .cp_index = 146 },
    .{ .char = 'ô', .cp_index = 147 },
    .{ .char = 'ö', .cp_index = 148 },
    .{ .char = 'ò', .cp_index = 149 },
    .{ .char = 'û', .cp_index = 150 },
    .{ .char = 'ù', .cp_index = 151 },
    .{ .char = 'ÿ', .cp_index = 152 },
    .{ .char = 'Ö', .cp_index = 153 },
    .{ .char = 'Ü', .cp_index = 154 },
    .{ .char = 'ø', .cp_index = 155 },
    .{ .char = '£', .cp_index = 156 },
    .{ .char = 'Ø', .cp_index = 157 },
    .{ .char = '×', .cp_index = 158 },
    .{ .char = 'ƒ', .cp_index = 159 },
    .{ .char = 'á', .cp_index = 160 },
    .{ .char = 'í', .cp_index = 161 },
    .{ .char = 'ó', .cp_index = 162 },
    .{ .char = 'ú', .cp_index = 163 },
    .{ .char = 'ñ', .cp_index = 164 },
    .{ .char = 'Ñ', .cp_index = 165 },
    .{ .char = 'ª', .cp_index = 166 },
    .{ .char = 'º', .cp_index = 167 },
    .{ .char = '¿', .cp_index = 168 },
    .{ .char = '®', .cp_index = 169 },
    .{ .char = '¬', .cp_index = 170 },
    .{ .char = '½', .cp_index = 171 },
    .{ .char = '¼', .cp_index = 172 },
    .{ .char = '¡', .cp_index = 173 },
    .{ .char = '«', .cp_index = 174 },
    .{ .char = '»', .cp_index = 175 },
    .{ .char = '░', .cp_index = 176 }, // Light shade
    .{ .char = '▒', .cp_index = 177 }, // Medium shade
    .{ .char = '▓', .cp_index = 178 }, // Dark shade
    .{ .char = '│', .cp_index = 179 }, // Box drawing single vertical
    .{ .char = '┤', .cp_index = 180 }, // Box drawing single vertical and left
    .{ .char = '╡', .cp_index = 181 }, // Box drawing double vertical and single left
    .{ .char = '╢', .cp_index = 182 }, // Box drawing single vertical and double left
    .{ .char = '╖', .cp_index = 183 }, // Box drawing double down and single left
    .{ .char = '╕', .cp_index = 184 }, // Box drawing double up and single left
    .{ .char = '╣', .cp_index = 185 }, // Box drawing double vertical and left
    .{ .char = '║', .cp_index = 186 }, // Box drawing double vertical
    .{ .char = '╗', .cp_index = 187 }, // Box drawing double up and left
    .{ .char = '╝', .cp_index = 188 }, // Box drawing double down and left
    .{ .char = '╜', .cp_index = 189 }, // Box drawing single down and double left
    .{ .char = '╛', .cp_index = 190 }, // Box drawing single up and double left
    .{ .char = '┐', .cp_index = 191 }, // Box drawing single down and left
    .{ .char = '└', .cp_index = 192 }, // Box drawing single up and right
    .{ .char = '┴', .cp_index = 193 }, // Box drawing single horizontal and up
    .{ .char = '┬', .cp_index = 194 }, // Box drawing single horizontal and down
    .{ .char = '├', .cp_index = 195 }, // Box drawing single vertical and right
    .{ .char = '─', .cp_index = 196 }, // Box drawing single horizontal
    .{ .char = '┼', .cp_index = 197 }, // Box drawing single vertical and horizontal
    .{ .char = '╚', .cp_index = 198 }, // Box drawing double up and right
    .{ .char = '╔', .cp_index = 199 }, // Box drawing double down and right
    .{ .char = '╩', .cp_index = 200 }, // Box drawing double horizontal and up
    .{ .char = '╦', .cp_index = 201 }, // Box drawing double horizontal and down
    .{ .char = '╠', .cp_index = 202 }, // Box drawing double vertical and right
    .{ .char = '═', .cp_index = 203 }, // Box drawing double horizontal
    .{ .char = '╬', .cp_index = 204 }, // Box drawing double vertical and horizontal
    .{ .char = '╧', .cp_index = 205 }, // Box drawing single horizontal and double up
    .{ .char = '╨', .cp_index = 206 }, // Box drawing single horizontal and double down
    .{ .char = '╤', .cp_index = 207 }, // Box drawing double up and single horizontal
    .{ .char = '╥', .cp_index = 208 }, // Box drawing double down and single horizontal
    .{ .char = '╙', .cp_index = 209 }, // Box drawing single up and double right
    .{ .char = '╘', .cp_index = 210 }, // Box drawing single down and double right
    .{ .char = '╒', .cp_index = 211 }, // Box drawing double down and single right
    .{ .char = '╓', .cp_index = 212 }, // Box drawing double up and single right
    .{ .char = '╫', .cp_index = 213 }, // Box drawing single vertical and double horizontal
    .{ .char = '╪', .cp_index = 214 }, // Box drawing double vertical and single horizontal
    .{ .char = '┘', .cp_index = 215 }, // Box drawing single up and left
    .{ .char = '┌', .cp_index = 216 }, // Box drawing single down and right
    .{ .char = '█', .cp_index = 217 }, // Full block
    .{ .char = '▄', .cp_index = 218 }, // Lower half block
    .{ .char = '▌', .cp_index = 219 }, // Left half block
    .{ .char = '▐', .cp_index = 220 }, // Right half block
    .{ .char = '▀', .cp_index = 221 }, // Upper half block
    .{ .char = 'α', .cp_index = 224 }, // Alpha
    .{ .char = 'ß', .cp_index = 225 }, // Beta (Sharp S)
    .{ .char = 'Γ', .cp_index = 226 }, // Gamma (Capital)
    .{ .char = 'π', .cp_index = 227 }, // Pi
    .{ .char = 'Σ', .cp_index = 228 }, // Sigma (Capital)
    .{ .char = 'σ', .cp_index = 229 }, // Sigma (Small)
    .{ .char = 'µ', .cp_index = 230 }, // Micro sign
    .{ .char = 'τ', .cp_index = 231 }, // Tau
    .{ .char = 'Φ', .cp_index = 232 }, // Phi (Capital)
    .{ .char = 'Θ', .cp_index = 233 }, // Theta (Capital)
    .{ .char = 'Ω', .cp_index = 234 }, // Omega (Capital)
    .{ .char = 'δ', .cp_index = 235 }, // Delta (Small)
    .{ .char = '∞', .cp_index = 236 }, // Infinity
    .{ .char = 'φ', .cp_index = 237 }, // Phi (Small)
    .{ .char = 'ε', .cp_index = 238 }, // Epsilon
    .{ .char = '∩', .cp_index = 239 }, // Intersection
    .{ .char = '≡', .cp_index = 240 }, // Identical to
    .{ .char = '±', .cp_index = 241 }, // Plus-minus sign
    .{ .char = '≥', .cp_index = 242 }, // Greater-than or equal to
    .{ .char = '≤', .cp_index = 243 }, // Less-than or equal to
    .{ .char = '⌠', .cp_index = 244 }, // Top half integral
    .{ .char = '⌡', .cp_index = 245 }, // Bottom half integral
    .{ .char = '÷', .cp_index = 246 }, // Division sign
    .{ .char = '≈', .cp_index = 247 }, // Almost equal to
    .{ .char = '°', .cp_index = 248 }, // Degree sign
    .{ .char = '∙', .cp_index = 249 }, // Bullet operator
    .{ .char = '·', .cp_index = 250 }, // Middle dot
    .{ .char = '√', .cp_index = 251 }, // Square root
    .{ .char = 'ⁿ', .cp_index = 252 }, // Superscript n
    .{ .char = '²', .cp_index = 253 }, // Superscript two
    .{ .char = '■', .cp_index = 254 }, // Black square
    .{ .char = '\xA0', .cp_index = 255 }, // Non-breaking space (often rendered as blank, but has a different meaning than ' ')
};

fn getCpIndex(char: u8) u8 {
  for (Codepage437Map) |mapping| {
    if (mapping.char == char){
      std.debug.print("Found char mapping: {d}-{d}\n", .{mapping.char, mapping.cp_index});
      return mapping.cp_index;
    }
  }
  return 0;
}

pub fn getTextureCoordinates(char: u8) rl.Vector2 {
  const cpIndex: f16 = @floatFromInt(getCpIndex(char));
  std.debug.print("Found cp_index: {d}\n", .{cpIndex});
  const y = @divFloor(cpIndex,tilesPerRows);
  const x = @mod(cpIndex,tilesPerRows);
  std.debug.print("Computed x: {d} and y: {d}\n", .{x, y});
  return rl.Vector2 {
    .x = x,
    .y = y,
  };
}



test "expect getTextureCoordinates to return the right coordinates for a char" {
  const expected = rl.Vector2 {.x = 0, .y = 4};
  const input = '@';

  try testing.expect(getTextureCoordinates(input) == expected);
}