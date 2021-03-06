/*
10 largest trade Associations

db.register.aggregate([
	{$match: {'subsection': 'Trade and business associations', 'hqCountry':'Belgium'}},
	{$sort: {'noFTEs': -1}},
	{$project: {'orgName':1, 'noFTEs':1}}
]).map(function(r) {return r._id}).slice(0,10).join('/')


*/

exports.headers = [ "_id"
	, "regDate"
	, "section"
	, "subsection"
	, "orgName"
	, "legalStatus"
	, "website"
	, "hqCountry"
	, "hqAddress"
	, "hqCity"
	, "hqPostCode"
	, "hqBox"
	, "hqPhone"
	, "belAddress"
	, "belCity"
	, "belPostCode"
	, "belBox"
	, "belPhone"
	, "legalPerson"
	, "position"
	, "euPerson"
	, "euPersonPosition"
	, "goals"
	, "level"
	, "initiatives"
	, "Relevant communication"
	, "High level groups"
	, "Consultative committees"
	, "Expert groups"
	, "Intergroups"
	, "forums"
	, "noPersons"
	, "noFTEs"
	, "noEP"
	, "epAccrdited"
	, "interests"
	, "memberships"
	, "organisations"
	, "Financial Start"
	, "Financial End"
	, "costsAbsolute"
	, "costEst"
	, "turnover"
	, "turnoverRange"
	, "clients"
	, "procurement"
	, "source"
	, "grants"
	, "grantsSource"];

exports.interests = [
	"Agriculture and Rural Development",
	"Education",
	"Research and Technology",
	"Competition",
	"Economic and Financial Affairs",
	"Employment and Social Affairs",
	"Enterprise",
	"Home Affairs",
	"Information Society",
	"Internal Market",
	"Justice and Fundamental Rights",
	"Taxation",
	"Trade",
	"Consumer Affairs",
	"Customs",
	"Energy",
	"Environment",
	"Food Safety",
	"Public Health",
	"Trans-European Networks",
	"Transport",
	"Culture",
	"Development",
	"Enlargement",
	"External Relations",
	"Foreign and Security Policy and Defence",
	"Humanitarian Aid",
	"Youth",
	"Audiovisual and Media",
	"Budget",
	"Climate Action",
	"Communication",
	"Fisheries and Aquaculture",
	"General and Institutional Affairs",
	"Regional Policy",
	"Sport"
]
