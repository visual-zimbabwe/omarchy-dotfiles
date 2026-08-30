.pragma library

// Standard base UTC offsets (in hours) and DST flags
var CITIES = [
  // Africa (No DST)
  { id: "harare", city: "Harare", country: "Zimbabwe", timezone: "Africa/Harare", baseOffset: 2, dst: "none" },
  { id: "johannesburg", city: "Johannesburg", country: "South Africa", timezone: "Africa/Johannesburg", baseOffset: 2, dst: "none" },
  { id: "cairo", city: "Cairo", country: "Egypt", timezone: "Africa/Cairo", baseOffset: 3, dst: "egypt" },
  { id: "nairobi", city: "Nairobi", country: "Kenya", timezone: "Africa/Nairobi", baseOffset: 3, dst: "none" },
  { id: "lagos", city: "Lagos", country: "Nigeria", timezone: "Africa/Lagos", baseOffset: 1, dst: "none" },
  { id: "casablanca", city: "Casablanca", country: "Morocco", timezone: "Africa/Casablanca", baseOffset: 1, dst: "none" },
  { id: "accra", city: "Accra", country: "Ghana", timezone: "Africa/Accra", baseOffset: 0, dst: "none" },
  { id: "addis_ababa", city: "Addis Ababa", country: "Ethiopia", timezone: "Africa/Addis_Ababa", baseOffset: 3, dst: "none" },
  { id: "kigali", city: "Kigali", country: "Rwanda", timezone: "Africa/Kigali", baseOffset: 2, dst: "none" },
  { id: "algiers", city: "Algiers", country: "Algeria", timezone: "Africa/Algiers", baseOffset: 1, dst: "none" },

  // Americas
  { id: "new_york", city: "New York", country: "United States", timezone: "America/New_York", baseOffset: -5, dst: "us" },
  { id: "los_angeles", city: "Los Angeles", country: "United States", timezone: "America/Los_Angeles", baseOffset: -8, dst: "us" },
  { id: "chicago", city: "Chicago", country: "United States", timezone: "America/Chicago", baseOffset: -6, dst: "us" },
  { id: "san_francisco", city: "San Francisco", country: "United States", timezone: "America/Los_Angeles", baseOffset: -8, dst: "us" },
  { id: "toronto", city: "Toronto", country: "Canada", timezone: "America/Toronto", baseOffset: -5, dst: "us" },
  { id: "vancouver", city: "Vancouver", country: "Canada", timezone: "America/Vancouver", baseOffset: -8, dst: "us" },
  { id: "mexico_city", city: "Mexico City", country: "Mexico", timezone: "America/Mexico_City", baseOffset: -6, dst: "none" },
  { id: "sao_paulo", city: "São Paulo", country: "Brazil", timezone: "America/Sao_Paulo", baseOffset: -3, dst: "none" },
  { id: "buenos_aires", city: "Buenos Aires", country: "Argentina", timezone: "America/Argentina/Buenos_Aires", baseOffset: -3, dst: "none" },
  { id: "santiago", city: "Santiago", country: "Chile", timezone: "America/Santiago", baseOffset: -4, dst: "chile" },
  { id: "bogota", city: "Bogotá", country: "Colombia", timezone: "America/Bogota", baseOffset: -5, dst: "none" },
  { id: "lima", city: "Lima", country: "Peru", timezone: "America/Lima", baseOffset: -5, dst: "none" },
  { id: "honolulu", city: "Honolulu", country: "United States", timezone: "Pacific/Honolulu", baseOffset: -10, dst: "none" },

  // Europe
  { id: "london", city: "London", country: "United Kingdom", timezone: "Europe/London", baseOffset: 0, dst: "eu" },
  { id: "paris", city: "Paris", country: "France", timezone: "Europe/Paris", baseOffset: 1, dst: "eu" },
  { id: "berlin", city: "Berlin", country: "Germany", timezone: "Europe/Berlin", baseOffset: 1, dst: "eu" },
  { id: "rome", city: "Rome", country: "Italy", timezone: "Europe/Rome", baseOffset: 1, dst: "eu" },
  { id: "madrid", city: "Madrid", country: "Spain", timezone: "Europe/Madrid", baseOffset: 1, dst: "eu" },
  { id: "amsterdam", city: "Amsterdam", country: "Netherlands", timezone: "Europe/Amsterdam", baseOffset: 1, dst: "eu" },
  { id: "zurich", city: "Zurich", country: "Switzerland", timezone: "Europe/Zurich", baseOffset: 1, dst: "eu" },
  { id: "stockholm", city: "Stockholm", country: "Sweden", timezone: "Europe/Stockholm", baseOffset: 1, dst: "eu" },
  { id: "oslo", city: "Oslo", country: "Norway", timezone: "Europe/Oslo", baseOffset: 1, dst: "eu" },
  { id: "vienna", city: "Vienna", country: "Austria", timezone: "Europe/Vienna", baseOffset: 1, dst: "eu" },
  { id: "warsaw", city: "Warsaw", country: "Poland", timezone: "Europe/Warsaw", baseOffset: 1, dst: "eu" },
  { id: "athens", city: "Athens", country: "Greece", timezone: "Europe/Athens", baseOffset: 2, dst: "eu" },
  { id: "istanbul", city: "Istanbul", country: "Turkey", timezone: "Europe/Istanbul", baseOffset: 3, dst: "none" },
  { id: "dublin", city: "Dublin", country: "Ireland", timezone: "Europe/Dublin", baseOffset: 0, dst: "eu" },

  // Asia & Middle East (mostly No DST)
  { id: "tokyo", city: "Tokyo", country: "Japan", timezone: "Asia/Tokyo", baseOffset: 9, dst: "none" },
  { id: "seoul", city: "Seoul", country: "South Korea", timezone: "Asia/Seoul", baseOffset: 9, dst: "none" },
  { id: "beijing", city: "Beijing", country: "China", timezone: "Asia/Shanghai", baseOffset: 8, dst: "none" },
  { id: "hong_kong", city: "Hong Kong", country: "Hong Kong", timezone: "Asia/Hong_Kong", baseOffset: 8, dst: "none" },
  { id: "singapore", city: "Singapore", country: "Singapore", timezone: "Asia/Singapore", baseOffset: 8, dst: "none" },
  { id: "bangkok", city: "Bangkok", country: "Thailand", timezone: "Asia/Bangkok", baseOffset: 7, dst: "none" },
  { id: "dubai", city: "Dubai", country: "United Arab Emirates", timezone: "Asia/Dubai", baseOffset: 4, dst: "none" },
  { id: "riyadh", city: "Riyadh", country: "Saudi Arabia", timezone: "Asia/Riyadh", baseOffset: 3, dst: "none" },
  { id: "doha", city: "Doha", country: "Qatar", timezone: "Asia/Qatar", baseOffset: 3, dst: "none" },
  { id: "mumbai", city: "Mumbai", country: "India", timezone: "Asia/Kolkata", baseOffset: 5.5, dst: "none" },
  { id: "delhi", city: "New Delhi", country: "India", timezone: "Asia/Kolkata", baseOffset: 5.5, dst: "none" },
  { id: "jakarta", city: "Jakarta", country: "Indonesia", timezone: "Asia/Jakarta", baseOffset: 7, dst: "none" },
  { id: "taipei", city: "Taipei", country: "Taiwan", timezone: "Asia/Taipei", baseOffset: 8, dst: "none" },
  { id: "kuala_lumpur", city: "Kuala Lumpur", country: "Malaysia", timezone: "Asia/Kuala_Lumpur", baseOffset: 8, dst: "none" },
  { id: "manila", city: "Manila", country: "Philippines", timezone: "Asia/Manila", baseOffset: 8, dst: "none" },
  { id: "tel_aviv", city: "Tel Aviv", country: "Israel", timezone: "Asia/Jerusalem", baseOffset: 2, dst: "israel" },

  // Oceania
  { id: "sydney", city: "Sydney", country: "Australia", timezone: "Australia/Sydney", baseOffset: 10, dst: "australia" },
  { id: "melbourne", city: "Melbourne", country: "Australia", timezone: "Australia/Melbourne", baseOffset: 10, dst: "australia" },
  { id: "brisbane", city: "Brisbane", country: "Australia", timezone: "Australia/Brisbane", baseOffset: 10, dst: "none" },
  { id: "auckland", city: "Auckland", country: "New Zealand", timezone: "Pacific/Auckland", baseOffset: 12, dst: "nz" }
];

function isUsDst(date) {
  var month = date.getUTCMonth(); // 0-11
  if (month < 2 || month > 10) return false;
  if (month > 2 && month < 10) return true;
  var day = date.getUTCDate();
  if (month === 2) return day >= 8; // March approx
  if (month === 10) return day < 7; // November approx
  return false;
}

function isEuDst(date) {
  var month = date.getUTCMonth();
  if (month < 2 || month > 9) return false;
  if (month > 2 && month < 9) return true;
  var day = date.getUTCDate();
  if (month === 2) return day >= 25; // Last Sunday March approx
  if (month === 9) return day < 25; // Last Sunday Oct approx
  return false;
}

function isAustraliaDst(date) {
  var month = date.getUTCMonth();
  return month >= 9 || month < 3; // Oct to April
}

function getCityOffsetHours(cityObj, date) {
  var d = date || new Date();
  var offset = Number(cityObj.baseOffset !== undefined ? cityObj.baseOffset : (cityObj.utcOffset || 0));
  var dstType = cityObj.dst || "none";

  if (dstType === "us" && isUsDst(d)) offset += 1;
  else if (dstType === "eu" && isEuDst(d)) offset += 1;
  else if (dstType === "australia" && isAustraliaDst(d)) offset += 1;
  else if (dstType === "nz" && isAustraliaDst(d)) offset += 1;
  else if (dstType === "israel" && isEuDst(d)) offset += 1;

  return offset;
}

function search(query) {
  if (!query || query.trim() === "") return CITIES.slice(0, 25);
  var q = query.toLowerCase().trim();
  return CITIES.filter(function(item) {
    return item.city.toLowerCase().indexOf(q) !== -1 ||
           item.country.toLowerCase().indexOf(q) !== -1 ||
           item.timezone.toLowerCase().indexOf(q) !== -1;
  });
}

function getById(id) {
  for (var i = 0; i < CITIES.length; i++) {
    if (CITIES[i].id === id) return CITIES[i];
  }
  return null;
}

function getByTimezone(tz) {
  for (var i = 0; i < CITIES.length; i++) {
    if (CITIES[i].timezone === tz) return CITIES[i];
  }
  return null;
}
