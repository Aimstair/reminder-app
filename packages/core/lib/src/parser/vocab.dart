/// Word lists used by the parser (docs/parser-test-set.md §3). Lowercase.
library;

const monthNames = <String, int>{
  'january': 1,
  'jan': 1,
  'february': 2,
  'feb': 2,
  'march': 3,
  'mar': 3,
  'april': 4,
  'apr': 4,
  'may': 5,
  'june': 6,
  'jun': 6,
  'july': 7,
  'jul': 7,
  'august': 8,
  'aug': 8,
  'september': 9,
  'sept': 9,
  'sep': 9,
  'october': 10,
  'oct': 10,
  'november': 11,
  'nov': 11,
  'december': 12,
  'dec': 12,
};

/// Longest first so regex alternation prefers full names.
final monthPattern = (monthNames.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');

/// ISO weekday numbers (Monday = 1).
const weekdayNames = <String, int>{
  'monday': 1,
  'mon': 1,
  'tuesday': 2,
  'tues': 2,
  'tue': 2,
  'wednesday': 3,
  'wed': 3,
  'thursday': 4,
  'thurs': 4,
  'thur': 4,
  'thu': 4,
  'friday': 5,
  'fri': 5,
  'saturday': 6,
  'sat': 6,
  'sunday': 7,
  'sun': 7,
};

final weekdayPattern = (weekdayNames.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');

const rruleDay = {1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA', 7: 'SU'};

const numberWords = <String, int>{
  'a': 1,
  'an': 1,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'twelve': 12,
};

/// PRS-16: zone abbreviations → IANA.
const zoneAbbreviations = <String, String>{
  'et': 'America/New_York',
  'est': 'America/New_York',
  'edt': 'America/New_York',
  'ct': 'America/Chicago',
  'cst': 'America/Chicago',
  'cdt': 'America/Chicago',
  'mt': 'America/Denver',
  'mst': 'America/Denver',
  'mdt': 'America/Denver',
  'pt': 'America/Los_Angeles',
  'pst': 'America/Los_Angeles',
  'pdt': 'America/Los_Angeles',
  'gmt': 'UTC',
  'utc': 'UTC',
  'bst': 'Europe/London',
  'cet': 'Europe/Paris',
  'cest': 'Europe/Paris',
  'jst': 'Asia/Tokyo',
  'aest': 'Australia/Sydney',
  'aedt': 'Australia/Sydney',
  'ist': 'Asia/Kolkata',
};

/// PRS-17: major cities → IANA.
const cityZones = <String, String>{
  'london': 'Europe/London',
  'paris': 'Europe/Paris',
  'berlin': 'Europe/Berlin',
  'tokyo': 'Asia/Tokyo',
  'sydney': 'Australia/Sydney',
  'singapore': 'Asia/Singapore',
  'dubai': 'Asia/Dubai',
  'new york': 'America/New_York',
  'chicago': 'America/Chicago',
  'la': 'America/Los_Angeles',
  'los angeles': 'America/Los_Angeles',
  'san francisco': 'America/Los_Angeles',
  'toronto': 'America/Toronto',
  'manila': 'Asia/Manila',
  'mumbai': 'Asia/Kolkata',
};

/// PRS-29 (1) Occasion keywords.
const occasionWords = ['birthday', 'bday', 'anniversary'];

/// PRS-29 (2) Meeting keywords/phrases.
const meetingPhrases = [
  'meeting',
  'call with',
  'standup',
  'stand-up',
  'sync',
  '1:1',
  'interview',
  'sprint planning',
  'retro',
  'demo with',
];

/// PRS-29 (3) Bill words (BIL-1). Trial and subscription words win over action verbs.
const trialWords = ['free trial', 'trial'];
const subscriptionWords = ['subscription', 'renews', 'auto-renews', 'autorenews'];
const paymentWords = [
  'bill',
  'bills',
  'rent',
  'mortgage',
  'tuition',
  'credit card',
  'loan',
  'premium',
  'payment',
  'utilities',
];

/// PRS-37 currency symbols (null = the default dollar), codes and words.
const currencySymbols = <String, String?>{
  r'$': null,
  '€': 'EUR',
  '£': 'GBP',
  '¥': 'JPY',
  '₱': 'PHP',
  '₹': 'INR',
  '₩': 'KRW',
  '₺': 'TRY',
};
const currencyCodes = [
  'usd', 'eur', 'gbp', 'jpy', 'php', 'inr', 'cad', 'aud', 'nzd', 'sgd', 'hkd', 'mxn', 'chf', 'cny', //
  'krw', 'try', 'brl', 'zar', 'sek', 'nok', 'dkk', 'pln',
];

/// Word → currency; null = the default dollar, 'peso' = the default peso.
const currencyWords = <String, String?>{
  'dollars': null,
  'dollar': null,
  'bucks': null,
  'euros': 'EUR',
  'euro': 'EUR',
  'pesos': 'peso',
  'yen': 'JPY',
  'rupees': 'INR',
};
const dollarCurrencies = {'USD', 'CAD', 'AUD', 'NZD', 'SGD', 'HKD', 'MXN'};
const pesoCurrencies = {'PHP', 'MXN', 'ARS', 'CLP', 'COP'};

/// PRS-29 (4) Action verbs that make an input a Task even with an Event word.
const taskVerbs = [
  'buy',
  'order',
  'book',
  'call',
  'email',
  'text',
  'pay',
  'send',
  'submit',
  'pick up',
  'prepare',
  'finish',
  'review',
  'renew',
  'cancel',
  'return',
  'clean',
  'fix',
  'check',
  'follow up',
  'remind',
];

/// PRS-29 (5) Event keywords.
const eventWords = [
  'dinner',
  'lunch',
  'brunch',
  'breakfast',
  'drinks',
  'party',
  'concert',
  'game',
  'flight',
  'appointment',
  'dentist',
  'doctor',
  'physio',
  'haircut',
  'wedding',
  'date night',
  'webinar',
  'workshop',
  'class',
  'practice',
];

/// PRS-14 meal default times for Events without a time.
const mealHours = {'breakfast': 8, 'brunch': 12, 'lunch': 12, 'dinner': 19, 'drinks': 19};

/// PRS-31 Work context keywords.
const workWords = [
  'client',
  'team',
  'report',
  'invoice',
  'deck',
  'slides',
  'contract',
  'timesheet',
  'board',
  'sprint',
  'manager',
  'office',
  'roadmap',
  'candidate',
  'webinar',
  'workshop',
  'budget',
];

/// PRS-39 holidays → Occasion · holiday (SUB-2), unless a party/dinner/… word follows ("Halloween party").
const holidayWords = [
  'christmas',
  'christmas eve',
  'xmas',
  "new year's",
  'new years',
  'new year',
  "new year's eve",
  'lunar new year',
  'chinese new year',
  'thanksgiving',
  'easter',
  'halloween',
  'hanukkah',
  'chanukah',
  'diwali',
  'eid',
  'ramadan',
  "valentine's day",
  'valentines day',
  "valentine's",
  "mother's day",
  'mothers day',
  "father's day",
  'fathers day',
  'independence day',
  'memorial day',
  'labor day',
  'labour day',
  'july 4th',
  'fourth of july',
  "st patrick's day",
  'public holiday',
  'bank holiday',
];

/// SUB-2 subtype words, checked within the guessed type. First group that matches wins.
const memorialWords = ['death anniversary', 'passing', 'passed away', 'memorial', 'remembrance', 'in memory', 'rip'];
const videoWords = ['zoom', 'google meet', 'meet', 'teams', 'video', 'webex', 'facetime', 'hangout', 'call with'];
const phoneWords = ['phone', 'phone call', 'dial in', 'dial-in', 'conference call'];
const inPersonWords = ['in person', 'in-person', 'office', 'onsite', 'on-site', 'coffee', 'lunch', 'visit', 'room'];
const appointmentWords = [
  'appointment',
  'appt',
  'dentist',
  'doctor',
  'physio',
  'haircut',
  'checkup',
  'check-up',
  'vet',
  'clinic',
  'therapy',
  'salon',
  'massage',
  'hospital',
];
const travelWords = ['flight', 'trip', 'travel', 'train', 'airport', 'hotel', 'vacation', 'cruise', 'road trip'];
const socialWords = [
  'dinner',
  'lunch',
  'brunch',
  'breakfast',
  'drinks',
  'party',
  'concert',
  'game',
  'wedding',
  'date night',
  'movie',
  'show',
  'festival',
  'night out',
  'bbq',
  'barbecue',
];
