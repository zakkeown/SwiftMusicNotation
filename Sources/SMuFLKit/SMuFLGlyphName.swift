import Foundation

/// SMuFL glyph names with their Unicode code points in the Private Use Area.
///
/// This enum contains the canonical glyph names from the SMuFL specification.
/// Each glyph maps to a specific Unicode code point (U+E000 onwards) that
/// SMuFL-compliant fonts implement.
///
/// Reference: https://w3c.github.io/smufl/latest/
public enum SMuFLGlyphName: String, Codable, CaseIterable, Sendable {

    // MARK: - Barlines (U+E030–U+E03F)

    case barlineSingle = "barlineSingle"                         // U+E030
    case barlineDouble = "barlineDouble"                         // U+E031
    case barlineFinal = "barlineFinal"                           // U+E032
    case barlineReverseFinal = "barlineReverseFinal"             // U+E033
    case barlineHeavy = "barlineHeavy"                           // U+E034
    case barlineHeavyHeavy = "barlineHeavyHeavy"                 // U+E035
    case barlineDashed = "barlineDashed"                         // U+E036
    case barlineDotted = "barlineDotted"                         // U+E037
    case barlineShort = "barlineShort"                           // U+E038
    case barlineTick = "barlineTick"                             // U+E039

    // MARK: - Repeats (U+E040–U+E04F)

    case repeatLeft = "repeatLeft"                               // U+E040
    case repeatRight = "repeatRight"                             // U+E041
    case repeatRightLeft = "repeatRightLeft"                     // U+E042
    case repeatDots = "repeatDots"                               // U+E043
    case repeatDot = "repeatDot"                                 // U+E044
    case dalSegno = "dalSegno"                                   // U+E045
    case daCapo = "daCapo"                                       // U+E046
    case segno = "segno"                                         // U+E047
    case coda = "coda"                                           // U+E048
    case codaSquare = "codaSquare"                               // U+E049

    // MARK: - Clefs (U+E050–U+E07F)

    case gClef = "gClef"                                         // U+E050
    case gClef8vb = "gClef8vb"                                   // U+E052
    case gClef8va = "gClef8va"                                   // U+E053
    case gClef15mb = "gClef15mb"                                 // U+E051
    case gClef15ma = "gClef15ma"                                 // U+E054
    case cClef = "cClef"                                         // U+E05C
    case fClef = "fClef"                                         // U+E062
    case fClef8vb = "fClef8vb"                                   // U+E064
    case fClef8va = "fClef8va"                                   // U+E065
    case fClef15mb = "fClef15mb"                                 // U+E063
    case fClef15ma = "fClef15ma"                                 // U+E066
    case unpitchedPercussionClef1 = "unpitchedPercussionClef1"   // U+E069
    case unpitchedPercussionClef2 = "unpitchedPercussionClef2"   // U+E06A
    case sixStringTabClef = "6stringTabClef"                     // U+E06D
    case fourStringTabClef = "4stringTabClef"                    // U+E06E

    // MARK: - Time Signature Digits (U+E080–U+E09F)

    case timeSig0 = "timeSig0"                                   // U+E080
    case timeSig1 = "timeSig1"                                   // U+E081
    case timeSig2 = "timeSig2"                                   // U+E082
    case timeSig3 = "timeSig3"                                   // U+E083
    case timeSig4 = "timeSig4"                                   // U+E084
    case timeSig5 = "timeSig5"                                   // U+E085
    case timeSig6 = "timeSig6"                                   // U+E086
    case timeSig7 = "timeSig7"                                   // U+E087
    case timeSig8 = "timeSig8"                                   // U+E088
    case timeSig9 = "timeSig9"                                   // U+E089
    case timeSigCommon = "timeSigCommon"                         // U+E08A
    case timeSigCutCommon = "timeSigCutCommon"                   // U+E08B
    case timeSigPlus = "timeSigPlus"                             // U+E08C
    case timeSigPlusSmall = "timeSigPlusSmall"                   // U+E08D
    case timeSigFractionalSlash = "timeSigFractionalSlash"       // U+E08E
    case timeSigEquals = "timeSigEquals"                         // U+E08F
    case timeSigMinus = "timeSigMinus"                           // U+E090
    case timeSigParensLeft = "timeSigParensLeft"                 // U+E094
    case timeSigParensRight = "timeSigParensRight"               // U+E095

    // MARK: - Noteheads (U+E0A0–U+E0FF)

    case noteheadDoubleWhole = "noteheadDoubleWhole"             // U+E0A0
    case noteheadDoubleWholeSquare = "noteheadDoubleWholeSquare" // U+E0A1
    case noteheadWhole = "noteheadWhole"                         // U+E0A2
    case noteheadHalf = "noteheadHalf"                           // U+E0A3
    case noteheadBlack = "noteheadBlack"                         // U+E0A4
    case noteheadNull = "noteheadNull"                           // U+E0A5
    case noteheadXDoubleWhole = "noteheadXDoubleWhole"           // U+E0A6
    case noteheadXWhole = "noteheadXWhole"                       // U+E0A7
    case noteheadXHalf = "noteheadXHalf"                         // U+E0A8
    case noteheadXBlack = "noteheadXBlack"                       // U+E0A9
    case noteheadPlusDoubleWhole = "noteheadPlusDoubleWhole"     // U+E0AA
    case noteheadPlusWhole = "noteheadPlusWhole"                 // U+E0AB
    case noteheadPlusHalf = "noteheadPlusHalf"                   // U+E0AC
    case noteheadPlusBlack = "noteheadPlusBlack"                 // U+E0AD
    case noteheadCircleXDoubleWhole = "noteheadCircleXDoubleWhole" // U+E0AE
    case noteheadCircleXWhole = "noteheadCircleXWhole"           // U+E0AF
    case noteheadCircleXHalf = "noteheadCircleXHalf"             // U+E0B0
    case noteheadCircleX = "noteheadCircleX"                     // U+E0B1
    case noteheadDiamondDoubleWhole = "noteheadDiamondDoubleWhole" // U+E0D8
    case noteheadDiamondWhole = "noteheadDiamondWhole"           // U+E0D9
    case noteheadDiamondHalf = "noteheadDiamondHalf"             // U+E0DA
    case noteheadDiamondBlack = "noteheadDiamondBlack"           // U+E0DB
    case noteheadTriangleUpDoubleWhole = "noteheadTriangleUpDoubleWhole" // U+E0BC
    case noteheadTriangleUpWhole = "noteheadTriangleUpWhole"     // U+E0BD
    case noteheadTriangleUpHalf = "noteheadTriangleUpHalf"       // U+E0BE
    case noteheadTriangleUpBlack = "noteheadTriangleUpBlack"     // U+E0BF
    case noteheadTriangleDownDoubleWhole = "noteheadTriangleDownDoubleWhole" // U+E0C0
    case noteheadTriangleDownWhole = "noteheadTriangleDownWhole" // U+E0C1
    case noteheadTriangleDownHalf = "noteheadTriangleDownHalf"   // U+E0C2
    case noteheadTriangleDownBlack = "noteheadTriangleDownBlack" // U+E0C3
    case noteheadParenthesis = "noteheadParenthesis"             // U+E0CE
    case noteheadParenthesisLeft = "noteheadParenthesisLeft"     // U+E0CE
    case noteheadParenthesisRight = "noteheadParenthesisRight"   // U+E0CF
    case noteheadSlashVerticalEnds = "noteheadSlashVerticalEnds" // U+E100
    case noteheadSlashHorizontalEnds = "noteheadSlashHorizontalEnds" // U+E101
    case noteheadSlashWhiteWhole = "noteheadSlashWhiteWhole"     // U+E102
    case noteheadSlashWhiteHalf = "noteheadSlashWhiteHalf"       // U+E103
    case noteheadSlashDiamondWhite = "noteheadSlashDiamondWhite" // U+E104
    case noteheadSlashX = "noteheadSlashX"                       // U+E105

    // MARK: - Augmentation Dots (U+E1E7)

    case augmentationDot = "augmentationDot"                     // U+E1E7

    // MARK: - Stems (U+E210–U+E21F)

    case stem = "stem"                                           // U+E210

    // MARK: - Tremolos (U+E220–U+E23F)

    case tremolo1 = "tremolo1"                                   // U+E220
    case tremolo2 = "tremolo2"                                   // U+E221
    case tremolo3 = "tremolo3"                                   // U+E222
    case tremolo4 = "tremolo4"                                   // U+E223
    case tremolo5 = "tremolo5"                                   // U+E224

    // MARK: - Flags (U+E240–U+E25F)

    case flag8thUp = "flag8thUp"                                 // U+E240
    case flag8thDown = "flag8thDown"                             // U+E241
    case flag16thUp = "flag16thUp"                               // U+E242
    case flag16thDown = "flag16thDown"                           // U+E243
    case flag32ndUp = "flag32ndUp"                               // U+E244
    case flag32ndDown = "flag32ndDown"                           // U+E245
    case flag64thUp = "flag64thUp"                               // U+E246
    case flag64thDown = "flag64thDown"                           // U+E247
    case flag128thUp = "flag128thUp"                             // U+E248
    case flag128thDown = "flag128thDown"                         // U+E249
    case flag256thUp = "flag256thUp"                             // U+E24A
    case flag256thDown = "flag256thDown"                         // U+E24B
    case flag512thUp = "flag512thUp"                             // U+E24C
    case flag512thDown = "flag512thDown"                         // U+E24D
    case flag1024thUp = "flag1024thUp"                           // U+E24E
    case flag1024thDown = "flag1024thDown"                       // U+E24F

    // MARK: - Accidentals (U+E260–U+E26F Standard)

    case accidentalFlat = "accidentalFlat"                       // U+E260
    case accidentalNatural = "accidentalNatural"                 // U+E261
    case accidentalSharp = "accidentalSharp"                     // U+E262
    case accidentalDoubleSharp = "accidentalDoubleSharp"         // U+E263
    case accidentalDoubleFlat = "accidentalDoubleFlat"           // U+E264
    case accidentalTripleSharp = "accidentalTripleSharp"         // U+E265
    case accidentalTripleFlat = "accidentalTripleFlat"           // U+E266
    case accidentalNaturalFlat = "accidentalNaturalFlat"         // U+E267
    case accidentalNaturalSharp = "accidentalNaturalSharp"       // U+E268
    case accidentalSharpSharp = "accidentalSharpSharp"           // U+E269
    case accidentalParensLeft = "accidentalParensLeft"           // U+E26A
    case accidentalParensRight = "accidentalParensRight"         // U+E26B
    case accidentalBracketLeft = "accidentalBracketLeft"         // U+E26C
    case accidentalBracketRight = "accidentalBracketRight"       // U+E26D

    // MARK: - Accidentals (Stein-Zimmermann microtonal)

    case accidentalQuarterToneFlatStein = "accidentalQuarterToneFlatStein"     // U+E280
    case accidentalThreeQuarterTonesFlatZimmermann = "accidentalThreeQuarterTonesFlatZimmermann" // U+E281
    case accidentalQuarterToneSharpStein = "accidentalQuarterToneSharpStein"   // U+E282
    case accidentalThreeQuarterTonesSharpStein = "accidentalThreeQuarterTonesSharpStein" // U+E283

    // MARK: - Accidentals (Gould arrow system)

    case accidentalSharpOneArrowUp = "accidentalSharpOneArrowUp"               // U+E2C0
    case accidentalSharpOneArrowDown = "accidentalSharpOneArrowDown"           // U+E2C1
    case accidentalFlatOneArrowUp = "accidentalFlatOneArrowUp"                 // U+E2C2
    case accidentalFlatOneArrowDown = "accidentalFlatOneArrowDown"             // U+E2C3
    case accidentalNaturalOneArrowUp = "accidentalNaturalOneArrowUp"           // U+E2C4
    case accidentalNaturalOneArrowDown = "accidentalNaturalOneArrowDown"       // U+E2C5
    case accidentalDoubleSharpOneArrowUp = "accidentalDoubleSharpOneArrowUp"   // U+E2C6
    case accidentalDoubleSharpOneArrowDown = "accidentalDoubleSharpOneArrowDown" // U+E2C7
    case accidentalDoubleFlatOneArrowUp = "accidentalDoubleFlatOneArrowUp"     // U+E2C8
    case accidentalDoubleFlatOneArrowDown = "accidentalDoubleFlatOneArrowDown" // U+E2C9

    // MARK: - Accidentals (Persian)

    case accidentalSori = "accidentalSori"                                     // U+E460
    case accidentalKoron = "accidentalKoron"                                   // U+E461

    // MARK: - Articulations (U+E4A0–U+E4BF)

    case articAccentAbove = "articAccentAbove"                   // U+E4A0
    case articAccentBelow = "articAccentBelow"                   // U+E4A1
    case articStaccatoAbove = "articStaccatoAbove"               // U+E4A2
    case articStaccatoBelow = "articStaccatoBelow"               // U+E4A3
    case articTenutoAbove = "articTenutoAbove"                   // U+E4A4
    case articTenutoBelow = "articTenutoBelow"                   // U+E4A5
    case articStaccatissimoAbove = "articStaccatissimoAbove"     // U+E4A6
    case articStaccatissimoBelow = "articStaccatissimoBelow"     // U+E4A7
    case articStaccatissimoWedgeAbove = "articStaccatissimoWedgeAbove" // U+E4A8
    case articStaccatissimoWedgeBelow = "articStaccatissimoWedgeBelow" // U+E4A9
    case articStaccatissimoStrokeAbove = "articStaccatissimoStrokeAbove" // U+E4AA
    case articStaccatissimoStrokeBelow = "articStaccatissimoStrokeBelow" // U+E4AB
    case articMarcatoAbove = "articMarcatoAbove"                 // U+E4AC
    case articMarcatoBelow = "articMarcatoBelow"                 // U+E4AD
    case articMarcatoStaccatoAbove = "articMarcatoStaccatoAbove" // U+E4AE
    case articMarcatoStaccatoBelow = "articMarcatoStaccatoBelow" // U+E4AF
    case articAccentStaccatoAbove = "articAccentStaccatoAbove"   // U+E4B0
    case articAccentStaccatoBelow = "articAccentStaccatoBelow"   // U+E4B1
    case articTenutoStaccatoAbove = "articTenutoStaccatoAbove"   // U+E4B2
    case articTenutoStaccatoBelow = "articTenutoStaccatoBelow"   // U+E4B3
    case articTenutoAccentAbove = "articTenutoAccentAbove"       // U+E4B4
    case articTenutoAccentBelow = "articTenutoAccentBelow"       // U+E4B5
    case articStressAbove = "articStressAbove"                   // U+E4B6
    case articStressBelow = "articStressBelow"                   // U+E4B7
    case articUnstressAbove = "articUnstressAbove"               // U+E4B8
    case articUnstressBelow = "articUnstressBelow"               // U+E4B9
    case articSoftAccentAbove = "articSoftAccentAbove"           // U+E4BA
    case articSoftAccentBelow = "articSoftAccentBelow"           // U+E4BB

    // MARK: - Holds and Pauses (U+E4C0–U+E4DF)

    case fermataAbove = "fermataAbove"                           // U+E4C0
    case fermataBelow = "fermataBelow"                           // U+E4C1
    case fermataVeryShortAbove = "fermataVeryShortAbove"         // U+E4C2
    case fermataVeryShortBelow = "fermataVeryShortBelow"         // U+E4C3
    case fermataShortAbove = "fermataShortAbove"                 // U+E4C4
    case fermataShortBelow = "fermataShortBelow"                 // U+E4C5
    case fermataLongAbove = "fermataLongAbove"                   // U+E4C6
    case fermataLongBelow = "fermataLongBelow"                   // U+E4C7
    case fermataVeryLongAbove = "fermataVeryLongAbove"           // U+E4C8
    case fermataVeryLongBelow = "fermataVeryLongBelow"           // U+E4C9
    case breathMarkComma = "breathMarkComma"                     // U+E4CE
    case breathMarkTick = "breathMarkTick"                       // U+E4CF
    case breathMarkUpbow = "breathMarkUpbow"                     // U+E4D0
    case breathMarkSalzedo = "breathMarkSalzedo"                 // U+E4D5
    case caesura = "caesura"                                     // U+E4D1
    case caesuraThick = "caesuraThick"                           // U+E4D2
    case caesuraShort = "caesuraShort"                           // U+E4D3
    case caesuraCurved = "caesuraCurved"                         // U+E4D4

    // MARK: - Rests (U+E4E0–U+E4FF)

    case restMaxima = "restMaxima"                               // U+E4E0
    case restLonga = "restLonga"                                 // U+E4E1
    case restDoubleWhole = "restDoubleWhole"                     // U+E4E2
    case restWhole = "restWhole"                                 // U+E4E3
    case restHalf = "restHalf"                                   // U+E4E4
    case restQuarter = "restQuarter"                             // U+E4E5
    case rest8th = "rest8th"                                     // U+E4E6
    case rest16th = "rest16th"                                   // U+E4E7
    case rest32nd = "rest32nd"                                   // U+E4E8
    case rest64th = "rest64th"                                   // U+E4E9
    case rest128th = "rest128th"                                 // U+E4EA
    case rest256th = "rest256th"                                 // U+E4EB
    case rest512th = "rest512th"                                 // U+E4EC
    case rest1024th = "rest1024th"                               // U+E4ED
    case restHBar = "restHBar"                                   // U+E4EE

    // MARK: - Dynamics (U+E520–U+E54F)

    case dynamicPiano = "dynamicPiano"                           // U+E520
    case dynamicMezzo = "dynamicMezzo"                           // U+E521
    case dynamicForte = "dynamicForte"                           // U+E522
    case dynamicRinforzando = "dynamicRinforzando"               // U+E523
    case dynamicSforzando = "dynamicSforzando"                   // U+E524
    case dynamicZ = "dynamicZ"                                   // U+E525
    case dynamicNiente = "dynamicNiente"                         // U+E526
    case dynamicPPPPPP = "dynamicPPPPPP"                         // U+E527
    case dynamicPPPPP = "dynamicPPPPP"                           // U+E528
    case dynamicPPPP = "dynamicPPPP"                             // U+E529
    case dynamicPPP = "dynamicPPP"                               // U+E52A
    case dynamicPP = "dynamicPP"                                 // U+E52B
    case dynamicMP = "dynamicMP"                                 // U+E52C
    case dynamicMF = "dynamicMF"                                 // U+E52D
    case dynamicPF = "dynamicPF"                                 // U+E52E
    case dynamicFF = "dynamicFF"                                 // U+E52F
    case dynamicFFF = "dynamicFFF"                               // U+E530
    case dynamicFFFF = "dynamicFFFF"                             // U+E531
    case dynamicFFFFF = "dynamicFFFFF"                           // U+E532
    case dynamicFFFFFF = "dynamicFFFFFF"                         // U+E533
    case dynamicFortePiano = "dynamicFortePiano"                 // U+E534
    case dynamicForzando = "dynamicForzando"                     // U+E535
    case dynamicSforzando1 = "dynamicSforzando1"                 // U+E536
    case dynamicSforzandoPiano = "dynamicSforzandoPiano"         // U+E537
    case dynamicSforzandoPianissimo = "dynamicSforzandoPianissimo" // U+E538
    case dynamicSforzato = "dynamicSforzato"                     // U+E539
    case dynamicSforzatoPiano = "dynamicSforzatoPiano"           // U+E53A
    case dynamicSforzatoFF = "dynamicSforzatoFF"                 // U+E53B
    case dynamicRinforzando1 = "dynamicRinforzando1"             // U+E53C
    case dynamicRinforzando2 = "dynamicRinforzando2"             // U+E53D
    case dynamicCrescendoHairpin = "dynamicCrescendoHairpin"     // U+E53E
    case dynamicDiminuendoHairpin = "dynamicDiminuendoHairpin"   // U+E53F

    // MARK: - Ornaments (U+E560–U+E59F)

    case ornamentTrill = "ornamentTrill"                         // U+E566
    case ornamentTurn = "ornamentTurn"                           // U+E567
    case ornamentTurnInverted = "ornamentTurnInverted"           // U+E568
    case ornamentTurnSlash = "ornamentTurnSlash"                 // U+E569
    case ornamentShortTrill = "ornamentShortTrill"               // U+E56C
    case ornamentMordent = "ornamentMordent"                     // U+E56D
    case ornamentMordentInverted = "ornamentMordentInverted"     // U+E56E
    case ornamentTremblement = "ornamentTremblement"             // U+E56F
    case ornamentPrallTriller = "ornamentPrallTriller"           // U+E570
    case ornamentUpPrall = "ornamentUpPrall"                     // U+E575
    case ornamentDownPrall = "ornamentDownPrall"                 // U+E576

    // MARK: - Brackets and Braces (U+E000–U+E00F)

    case brace = "brace"                                         // U+E000
    case bracket = "bracket"                                     // U+E002
    case bracketTop = "bracketTop"                               // U+E003
    case bracketBottom = "bracketBottom"                         // U+E004
    case systemDivider = "systemDivider"                         // U+E007
    case systemDividerLong = "systemDividerLong"                 // U+E008

    // MARK: - Multi-bar Rests

    case restHBarLeft = "restHBarLeft"                           // U+E500
    case restHBarMiddle = "restHBarMiddle"                       // U+E501
    case restHBarRight = "restHBarRight"                         // U+E502

    // MARK: - Tuplet Numbers (U+E880–U+E88F)

    case tuplet0 = "tuplet0"                                     // U+E880
    case tuplet1 = "tuplet1"                                     // U+E881
    case tuplet2 = "tuplet2"                                     // U+E882
    case tuplet3 = "tuplet3"                                     // U+E883
    case tuplet4 = "tuplet4"                                     // U+E884
    case tuplet5 = "tuplet5"                                     // U+E885
    case tuplet6 = "tuplet6"                                     // U+E886
    case tuplet7 = "tuplet7"                                     // U+E887
    case tuplet8 = "tuplet8"                                     // U+E888
    case tuplet9 = "tuplet9"                                     // U+E889
    case tupletColon = "tupletColon"                             // U+E88A

    // MARK: - Grace Notes

    case graceNoteSlashStemUp = "graceNoteSlashStemUp"           // U+E560
    case graceNoteSlashStemDown = "graceNoteSlashStemDown"       // U+E561

    // MARK: - Octave Lines

    case ottavaAlta = "ottavaAlta"                               // U+E510
    case ottavaBassaVb = "ottavaBassaVb"                         // U+E511
    case quindicesima = "quindicesima"                           // U+E514
    case quindicesimaAlta = "quindicesimaAlta"                   // U+E515
    case quindicesimaBassa = "quindicesimaBassa"                 // U+E516

    // MARK: - String Techniques (U+E610–U+E62F)

    case stringsDownBow = "stringsDownBow"                       // U+E610
    case stringsDownBowTurned = "stringsDownBowTurned"           // U+E611
    case stringsUpBow = "stringsUpBow"                           // U+E612
    case stringsUpBowTurned = "stringsUpBowTurned"               // U+E613
    case stringsHarmonic = "stringsHarmonic"                     // U+E614
    case stringsHalfHarmonic = "stringsHalfHarmonic"             // U+E615
    case stringsMuteOn = "stringsMuteOn"                         // U+E622
    case stringsMuteOff = "stringsMuteOff"                       // U+E623
    case stringsThumbPosition = "stringsThumbPosition"           // U+E624
    case stringsThumbPositionTurned = "stringsThumbPositionTurned" // U+E625
    case stringsVibratoPulse = "stringsVibratoPulse"             // U+E620
    case stringsBowBehindBridge = "stringsBowBehindBridge"       // U+E618
    case stringsBowOnBridge = "stringsBowOnBridge"               // U+E619
    case stringsBowOnTailpiece = "stringsBowOnTailpiece"         // U+E61A
    case stringsJeteAbove = "stringsJeteAbove"                   // U+E626
    case stringsJeteBelow = "stringsJeteBelow"                   // U+E627
    case stringsFouette = "stringsFouette"                       // U+E628
    case stringsChangeBowDirection = "stringsChangeBowDirection" // U+E629
    case stringsSnapPizzicatoAbove = "stringsSnapPizzicatoAbove" // U+E630
    case stringsSnapPizzicatoBelow = "stringsSnapPizzicatoBelow" // U+E631

    /// The Unicode code point for this glyph in the SMuFL Private Use Area.
    ///
    /// Code points follow the SMuFL specification. For glyphs not listed here,
    /// use `LoadedSMuFLFont.glyph(for:)` which looks up the glyph in the font's
    /// metadata at runtime.
    public var codePoint: UInt32 {
        switch self {
        // Clefs
        case .gClef: return 0xE050
        case .gClef8vb: return 0xE052
        case .gClef8va: return 0xE053
        case .gClef15mb: return 0xE051
        case .gClef15ma: return 0xE054
        case .cClef: return 0xE05C
        case .fClef: return 0xE062
        case .fClef8vb: return 0xE064
        case .fClef8va: return 0xE065
        case .fClef15mb: return 0xE063
        case .fClef15ma: return 0xE066
        case .unpitchedPercussionClef1: return 0xE069
        case .unpitchedPercussionClef2: return 0xE06A
        case .sixStringTabClef: return 0xE06D
        case .fourStringTabClef: return 0xE06E

        // Time signatures
        case .timeSig0: return 0xE080
        case .timeSig1: return 0xE081
        case .timeSig2: return 0xE082
        case .timeSig3: return 0xE083
        case .timeSig4: return 0xE084
        case .timeSig5: return 0xE085
        case .timeSig6: return 0xE086
        case .timeSig7: return 0xE087
        case .timeSig8: return 0xE088
        case .timeSig9: return 0xE089
        case .timeSigCommon: return 0xE08A
        case .timeSigCutCommon: return 0xE08B
        case .timeSigPlus: return 0xE08C
        case .timeSigPlusSmall: return 0xE08D
        case .timeSigFractionalSlash: return 0xE08E
        case .timeSigEquals: return 0xE08F
        case .timeSigMinus: return 0xE090
        case .timeSigParensLeft: return 0xE094
        case .timeSigParensRight: return 0xE095

        // Noteheads
        case .noteheadDoubleWhole: return 0xE0A0
        case .noteheadDoubleWholeSquare: return 0xE0A1
        case .noteheadWhole: return 0xE0A2
        case .noteheadHalf: return 0xE0A3
        case .noteheadBlack: return 0xE0A4
        case .noteheadNull: return 0xE0A5
        case .noteheadXDoubleWhole: return 0xE0A6
        case .noteheadXWhole: return 0xE0A7
        case .noteheadXHalf: return 0xE0A8
        case .noteheadXBlack: return 0xE0A9
        case .noteheadPlusDoubleWhole: return 0xE0AA
        case .noteheadPlusWhole: return 0xE0AB
        case .noteheadPlusHalf: return 0xE0AC
        case .noteheadPlusBlack: return 0xE0AD
        case .noteheadCircleXDoubleWhole: return 0xE0AE
        case .noteheadCircleXWhole: return 0xE0AF
        case .noteheadCircleXHalf: return 0xE0B0
        case .noteheadCircleX: return 0xE0B1
        case .noteheadTriangleUpDoubleWhole: return 0xE0BC
        case .noteheadTriangleUpWhole: return 0xE0BD
        case .noteheadTriangleUpHalf: return 0xE0BE
        case .noteheadTriangleUpBlack: return 0xE0BF
        case .noteheadTriangleDownDoubleWhole: return 0xE0C0
        case .noteheadTriangleDownWhole: return 0xE0C1
        case .noteheadTriangleDownHalf: return 0xE0C2
        case .noteheadTriangleDownBlack: return 0xE0C3
        case .noteheadParenthesis: return 0xE0CE
        case .noteheadParenthesisLeft: return 0xE0CE
        case .noteheadParenthesisRight: return 0xE0CF
        case .noteheadDiamondDoubleWhole: return 0xE0D8
        case .noteheadDiamondWhole: return 0xE0D9
        case .noteheadDiamondHalf: return 0xE0DA
        case .noteheadDiamondBlack: return 0xE0DB
        case .noteheadSlashVerticalEnds: return 0xE100
        case .noteheadSlashHorizontalEnds: return 0xE101
        case .noteheadSlashWhiteWhole: return 0xE102
        case .noteheadSlashWhiteHalf: return 0xE103
        case .noteheadSlashDiamondWhite: return 0xE104
        case .noteheadSlashX: return 0xE105

        // Augmentation dot
        case .augmentationDot: return 0xE1E7

        // Stems
        case .stem: return 0xE210

        // Tremolos
        case .tremolo1: return 0xE220
        case .tremolo2: return 0xE221
        case .tremolo3: return 0xE222
        case .tremolo4: return 0xE223
        case .tremolo5: return 0xE224

        // Flags
        case .flag8thUp: return 0xE240
        case .flag8thDown: return 0xE241
        case .flag16thUp: return 0xE242
        case .flag16thDown: return 0xE243
        case .flag32ndUp: return 0xE244
        case .flag32ndDown: return 0xE245
        case .flag64thUp: return 0xE246
        case .flag64thDown: return 0xE247
        case .flag128thUp: return 0xE248
        case .flag128thDown: return 0xE249
        case .flag256thUp: return 0xE24A
        case .flag256thDown: return 0xE24B
        case .flag512thUp: return 0xE24C
        case .flag512thDown: return 0xE24D
        case .flag1024thUp: return 0xE24E
        case .flag1024thDown: return 0xE24F

        // Accidentals
        case .accidentalFlat: return 0xE260
        case .accidentalNatural: return 0xE261
        case .accidentalSharp: return 0xE262
        case .accidentalDoubleSharp: return 0xE263
        case .accidentalDoubleFlat: return 0xE264
        case .accidentalTripleSharp: return 0xE265
        case .accidentalTripleFlat: return 0xE266
        case .accidentalNaturalFlat: return 0xE267
        case .accidentalNaturalSharp: return 0xE268
        case .accidentalSharpSharp: return 0xE269
        case .accidentalParensLeft: return 0xE26A
        case .accidentalParensRight: return 0xE26B
        case .accidentalBracketLeft: return 0xE26C
        case .accidentalBracketRight: return 0xE26D
        case .accidentalQuarterToneFlatStein: return 0xE280
        case .accidentalThreeQuarterTonesFlatZimmermann: return 0xE281
        case .accidentalQuarterToneSharpStein: return 0xE282
        case .accidentalThreeQuarterTonesSharpStein: return 0xE283

        // Accidentals (Gould arrow system)
        case .accidentalSharpOneArrowUp: return 0xE2C0
        case .accidentalSharpOneArrowDown: return 0xE2C1
        case .accidentalFlatOneArrowUp: return 0xE2C2
        case .accidentalFlatOneArrowDown: return 0xE2C3
        case .accidentalNaturalOneArrowUp: return 0xE2C4
        case .accidentalNaturalOneArrowDown: return 0xE2C5
        case .accidentalDoubleSharpOneArrowUp: return 0xE2C6
        case .accidentalDoubleSharpOneArrowDown: return 0xE2C7
        case .accidentalDoubleFlatOneArrowUp: return 0xE2C8
        case .accidentalDoubleFlatOneArrowDown: return 0xE2C9

        // Accidentals (Persian)
        case .accidentalSori: return 0xE460
        case .accidentalKoron: return 0xE461

        // Rests
        case .restMaxima: return 0xE4E0
        case .restLonga: return 0xE4E1
        case .restDoubleWhole: return 0xE4E2
        case .restWhole: return 0xE4E3
        case .restHalf: return 0xE4E4
        case .restQuarter: return 0xE4E5
        case .rest8th: return 0xE4E6
        case .rest16th: return 0xE4E7
        case .rest32nd: return 0xE4E8
        case .rest64th: return 0xE4E9
        case .rest128th: return 0xE4EA
        case .rest256th: return 0xE4EB
        case .rest512th: return 0xE4EC
        case .rest1024th: return 0xE4ED
        case .restHBar: return 0xE4EE
        case .restHBarLeft: return 0xE500
        case .restHBarMiddle: return 0xE501
        case .restHBarRight: return 0xE502

        // Barlines
        case .barlineSingle: return 0xE030
        case .barlineDouble: return 0xE031
        case .barlineFinal: return 0xE032
        case .barlineReverseFinal: return 0xE033
        case .barlineHeavy: return 0xE034
        case .barlineHeavyHeavy: return 0xE035
        case .barlineDashed: return 0xE036
        case .barlineDotted: return 0xE037
        case .barlineShort: return 0xE038
        case .barlineTick: return 0xE039

        // Repeats
        case .repeatLeft: return 0xE040
        case .repeatRight: return 0xE041
        case .repeatRightLeft: return 0xE042
        case .repeatDots: return 0xE043
        case .repeatDot: return 0xE044
        case .dalSegno: return 0xE045
        case .daCapo: return 0xE046
        case .segno: return 0xE047
        case .coda: return 0xE048
        case .codaSquare: return 0xE049

        // Articulations
        case .articAccentAbove: return 0xE4A0
        case .articAccentBelow: return 0xE4A1
        case .articStaccatoAbove: return 0xE4A2
        case .articStaccatoBelow: return 0xE4A3
        case .articTenutoAbove: return 0xE4A4
        case .articTenutoBelow: return 0xE4A5
        case .articStaccatissimoAbove: return 0xE4A6
        case .articStaccatissimoBelow: return 0xE4A7
        case .articStaccatissimoWedgeAbove: return 0xE4A8
        case .articStaccatissimoWedgeBelow: return 0xE4A9
        case .articStaccatissimoStrokeAbove: return 0xE4AA
        case .articStaccatissimoStrokeBelow: return 0xE4AB
        case .articMarcatoAbove: return 0xE4AC
        case .articMarcatoBelow: return 0xE4AD
        case .articMarcatoStaccatoAbove: return 0xE4AE
        case .articMarcatoStaccatoBelow: return 0xE4AF
        case .articAccentStaccatoAbove: return 0xE4B0
        case .articAccentStaccatoBelow: return 0xE4B1
        case .articTenutoStaccatoAbove: return 0xE4B2
        case .articTenutoStaccatoBelow: return 0xE4B3
        case .articTenutoAccentAbove: return 0xE4B4
        case .articTenutoAccentBelow: return 0xE4B5
        case .articStressAbove: return 0xE4B6
        case .articStressBelow: return 0xE4B7
        case .articUnstressAbove: return 0xE4B8
        case .articUnstressBelow: return 0xE4B9
        case .articSoftAccentAbove: return 0xE4BA
        case .articSoftAccentBelow: return 0xE4BB

        // Holds and pauses
        case .fermataAbove: return 0xE4C0
        case .fermataBelow: return 0xE4C1
        case .fermataVeryShortAbove: return 0xE4C2
        case .fermataVeryShortBelow: return 0xE4C3
        case .fermataShortAbove: return 0xE4C4
        case .fermataShortBelow: return 0xE4C5
        case .fermataLongAbove: return 0xE4C6
        case .fermataLongBelow: return 0xE4C7
        case .fermataVeryLongAbove: return 0xE4C8
        case .fermataVeryLongBelow: return 0xE4C9
        case .breathMarkComma: return 0xE4CE
        case .breathMarkTick: return 0xE4CF
        case .breathMarkUpbow: return 0xE4D0
        case .breathMarkSalzedo: return 0xE4D5
        case .caesura: return 0xE4D1
        case .caesuraThick: return 0xE4D2
        case .caesuraShort: return 0xE4D3
        case .caesuraCurved: return 0xE4D4

        // Dynamics
        case .dynamicPiano: return 0xE520
        case .dynamicMezzo: return 0xE521
        case .dynamicForte: return 0xE522
        case .dynamicRinforzando: return 0xE523
        case .dynamicSforzando: return 0xE524
        case .dynamicZ: return 0xE525
        case .dynamicNiente: return 0xE526
        case .dynamicPPPPPP: return 0xE527
        case .dynamicPPPPP: return 0xE528
        case .dynamicPPPP: return 0xE529
        case .dynamicPPP: return 0xE52A
        case .dynamicPP: return 0xE52B
        case .dynamicMP: return 0xE52C
        case .dynamicMF: return 0xE52D
        case .dynamicPF: return 0xE52E
        case .dynamicFF: return 0xE52F
        case .dynamicFFF: return 0xE530
        case .dynamicFFFF: return 0xE531
        case .dynamicFFFFF: return 0xE532
        case .dynamicFFFFFF: return 0xE533
        case .dynamicFortePiano: return 0xE534
        case .dynamicForzando: return 0xE535
        case .dynamicSforzando1: return 0xE536
        case .dynamicSforzandoPiano: return 0xE537
        case .dynamicSforzandoPianissimo: return 0xE538
        case .dynamicSforzato: return 0xE539
        case .dynamicSforzatoPiano: return 0xE53A
        case .dynamicSforzatoFF: return 0xE53B
        case .dynamicRinforzando1: return 0xE53C
        case .dynamicRinforzando2: return 0xE53D
        case .dynamicCrescendoHairpin: return 0xE53E
        case .dynamicDiminuendoHairpin: return 0xE53F

        // Ornaments
        case .ornamentTrill: return 0xE566
        case .ornamentTurn: return 0xE567
        case .ornamentTurnInverted: return 0xE568
        case .ornamentTurnSlash: return 0xE569
        case .ornamentShortTrill: return 0xE56C
        case .ornamentMordent: return 0xE56D
        case .ornamentMordentInverted: return 0xE56E
        case .ornamentTremblement: return 0xE56F
        case .ornamentPrallTriller: return 0xE570
        case .ornamentUpPrall: return 0xE575
        case .ornamentDownPrall: return 0xE576

        // Brackets
        case .brace: return 0xE000
        case .bracket: return 0xE002
        case .bracketTop: return 0xE003
        case .bracketBottom: return 0xE004
        case .systemDivider: return 0xE007
        case .systemDividerLong: return 0xE008

        // Tuplets
        case .tuplet0: return 0xE880
        case .tuplet1: return 0xE881
        case .tuplet2: return 0xE882
        case .tuplet3: return 0xE883
        case .tuplet4: return 0xE884
        case .tuplet5: return 0xE885
        case .tuplet6: return 0xE886
        case .tuplet7: return 0xE887
        case .tuplet8: return 0xE888
        case .tuplet9: return 0xE889
        case .tupletColon: return 0xE88A

        // Grace notes
        case .graceNoteSlashStemUp: return 0xE560
        case .graceNoteSlashStemDown: return 0xE561

        // Octave lines
        case .ottavaAlta: return 0xE510
        case .ottavaBassaVb: return 0xE511
        case .quindicesima: return 0xE514
        case .quindicesimaAlta: return 0xE515
        case .quindicesimaBassa: return 0xE516

        // String techniques
        case .stringsDownBow: return 0xE610
        case .stringsDownBowTurned: return 0xE611
        case .stringsUpBow: return 0xE612
        case .stringsUpBowTurned: return 0xE613
        case .stringsHarmonic: return 0xE614
        case .stringsHalfHarmonic: return 0xE615
        case .stringsBowBehindBridge: return 0xE618
        case .stringsBowOnBridge: return 0xE619
        case .stringsBowOnTailpiece: return 0xE61A
        case .stringsVibratoPulse: return 0xE620
        case .stringsMuteOn: return 0xE622
        case .stringsMuteOff: return 0xE623
        case .stringsThumbPosition: return 0xE624
        case .stringsThumbPositionTurned: return 0xE625
        case .stringsJeteAbove: return 0xE626
        case .stringsJeteBelow: return 0xE627
        case .stringsFouette: return 0xE628
        case .stringsChangeBowDirection: return 0xE629
        case .stringsSnapPizzicatoAbove: return 0xE630
        case .stringsSnapPizzicatoBelow: return 0xE631
        }
    }

    /// The Unicode character for this glyph, if the codepoint is valid.
    ///
    /// All SMuFL codepoints are in the valid Unicode Private Use Area (0xE000-0xF8FF),
    /// so this property should always return a character for valid enum cases.
    public var character: Character? {
        guard let scalar = UnicodeScalar(codePoint) else {
            return nil
        }
        return Character(scalar)
    }

    /// The string representation for rendering, if the codepoint is valid.
    public var string: String? {
        character.map { String($0) }
    }
}

// MARK: - Glyph Lookup Helpers

extension SMuFLGlyphName {
    /// Returns the time signature digit glyph for a given digit (0-9).
    public static func timeSigDigit(_ digit: Int) -> SMuFLGlyphName? {
        guard (0...9).contains(digit) else { return nil }
        return [.timeSig0, .timeSig1, .timeSig2, .timeSig3, .timeSig4,
                .timeSig5, .timeSig6, .timeSig7, .timeSig8, .timeSig9][digit]
    }

    /// Returns the tuplet digit glyph for a given digit (0-9).
    public static func tupletDigit(_ digit: Int) -> SMuFLGlyphName? {
        guard (0...9).contains(digit) else { return nil }
        return [.tuplet0, .tuplet1, .tuplet2, .tuplet3, .tuplet4,
                .tuplet5, .tuplet6, .tuplet7, .tuplet8, .tuplet9][digit]
    }

    /// Returns the flag glyph for a given beam count and stem direction.
    public static func flag(beamCount: Int, stemUp: Bool) -> SMuFLGlyphName? {
        guard beamCount >= 1 else { return nil }
        let flags: [(up: SMuFLGlyphName, down: SMuFLGlyphName)] = [
            (.flag8thUp, .flag8thDown),
            (.flag16thUp, .flag16thDown),
            (.flag32ndUp, .flag32ndDown),
            (.flag64thUp, .flag64thDown),
            (.flag128thUp, .flag128thDown),
            (.flag256thUp, .flag256thDown),
            (.flag512thUp, .flag512thDown),
            (.flag1024thUp, .flag1024thDown)
        ]
        guard beamCount <= flags.count else { return nil }
        return stemUp ? flags[beamCount - 1].up : flags[beamCount - 1].down
    }

    /// Returns the rest glyph for a given number of beams (duration level).
    /// 0 = whole, 1 = half, 2 = quarter, etc.
    public static func rest(forDurationLevel level: Int) -> SMuFLGlyphName {
        let rests: [SMuFLGlyphName] = [
            .restWhole,      // 0 - whole
            .restHalf,       // 1 - half
            .restQuarter,    // 2 - quarter
            .rest8th,        // 3 - eighth
            .rest16th,       // 4 - 16th
            .rest32nd,       // 5 - 32nd
            .rest64th,       // 6 - 64th
            .rest128th,      // 7 - 128th
            .rest256th       // 8 - 256th
        ]
        guard level >= 0 && level < rests.count else {
            return .restQuarter
        }
        return rests[level]
    }

    /// Returns rest glyph by name for special durations.
    public static func restMaximaGlyph() -> SMuFLGlyphName { .restMaxima }
    public static func restLongaGlyph() -> SMuFLGlyphName { .restLonga }
    public static func restBreveGlyph() -> SMuFLGlyphName { .restDoubleWhole }
}
