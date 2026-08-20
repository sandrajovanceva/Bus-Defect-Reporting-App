"""The JSP Skopje bus numbers, taken from the operator's public schedule.

Source: https://skopjebus.mk/en/schedule/  (retrieved 2026-08-20)

Numbers are stored exactly as JSP prints them. The site mixes Latin lookalike
characters into otherwise Cyrillic labels (21A, 11a, 66a, 80a); those are
normalised to Cyrillic here so a number maps to exactly one bus.
"""

# category -> numbers, in the order the operator lists them.
BUS_NUMBERS: dict[str, list[str]] = {
    "urban": [
        "2", "2А", "3Б", "4", "5", "5А", "7", "8", "9", "9П", "12П", "13",
        "15", "15А", "16", "17", "19", "19П", "20П", "21", "21А", "22",
        "22П", "22А", "23П", "24", "25", "27", "28", "35", "41", "41А",
        "42", "43", "45П", "50", "50А", "57", "57А", "59", "59А", "59Б",
        "65В",
    ],
    "regional": [
        "11П", "11а", "18", "18а", "31", "33", "44", "47", "47аП", "51",
        "51а", "52", "52П", "53", "54П", "55П", "55а", "55в", "56", "58",
        "58а", "58б", "60", "61", "61П", "62", "63", "63П", "63А", "64А",
        "65", "65А", "66", "66а", "67", "68", "70", "71", "73П", "74",
        "80", "80а", "81", "111", "118", "160", "162", "163", "164", "165",
        "165б", "166", "167", "180",
    ],
    "night": [
        "2Н", "5Н", "7Н", "22Н", "24Н", "41Н", "50Н", "57Н", "65ВН",
    ],
}

ALL_BUS_NUMBERS: list[str] = [
    number for numbers in BUS_NUMBERS.values() for number in numbers
]

BUS_CATEGORIES = tuple(BUS_NUMBERS)
