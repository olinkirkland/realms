Abbreviation | Name | Description
------------ | ------------ | -------------
F | Food | If a Region produces more Food than it consumes, it receives a bonus to Growth and Happiness equal to 10% of the surplus Food. Otherwise, a negative amount of Food incurs a slight penalty to Growth. If a Region doesn't produce enough food and the Realm the Region belongs to has a negative total Food amount, the Region gets a massive penalty to Growth and Happiness.
W | Wealth | The value of the Region in cold, hard cash. This value is taxed at the Region's tax rate and that amount is added to the Treasury each turn.
G | Growth | This value is added to the Region's Wealth every turn.
D | Defense | Structures or fortifications designed to impede attackers.
I | Siege Holdout | How long a City can last under siege.
H | Happiness | Together with Repression, this value reflects the Region's Public Order. If Public Order drops below zero, a rebellion is more likely to occur in the Region.
R | Repression | Together with Happiness, this value reflects the Region's Public Order. During a rebellion, the strength of rebel forces is determined by a Public Order that relies heavily on Repression.
A | Garrison Troops | A Garrison is composed of troops that defend a City or Town when attacked, but cannot be mustered to march with an Army. They can, however, reinforce Armies within their influence radius, but return to their City or Town when the battle is complete.
C | Culture | The Region can have multiple Cultures present, and most do. Regions receive a bonus to Happiness from the presence of the Regeion's Realm's Culture.
S | Sanitation | The cleanliness of the Region is crucial to keeping out disease. Regions with negative Sanitation have a high chance of disease breaking out. Disease brings with it massive penalties to Growth and Public Order.
E | Research Speed | The speed at which technologies in the Tech Tree are researched is affected by this value.
X | Tax Rate | The percent of the Region's Wealth that is added to the Treasury each turn.
M | Movement | A bonus to the movement speed of all armies present in the Region.

## ADMINISTRATION

Name | Tier | Effects | Description
------------ | ------------ | ------------- | -------------
**Governor's Residence** | 1 | +R +X +W -F | 
**Governor's Estate** | 2 | +R +X +W -F | 
**Governor's Palace** | 3 | +R +X +W -F | 
**Royal Court [Capital Only]** | 4 | +R +X +W +A -F | 

## AGRICULTURE

Name | Tier | Effects | Description
------------ | ------------ | ------------- | -------------
**Water Mill [River Only]** | 1 | +F +W | 
**Wind Mill [Non-River Only]** | 1 | +F +W | 

## DEFENSE

Name | Tier | Effects | Description
------------ | ------------ | ------------- | -------------
**Hill Fort** | 1 | +D +I +R +A -F -W | 
**Motte and Bailey** | 2 | +D +I +R +A -F -W | 
**Wooden Castle** | 3 | +D +I +R +A -F -W |
**Castle** | 4 | +D +I +R +A -F -W | 

## RELIGION

Holy Ground
+H +C
-F
  Chapel
  +H +C
  -F
    Church
	+H +C
	-F
      Cathedral
	  +H +C
	  -F

Monastery
+H +C
  Monastic Brewery
  +H +C +G
    Monastic Compound
	+H +C +G
  Monastic Library
  +H +C +E
  -F
    Monastic Institute
	+H +C +E
	-F

## INDUSTRY

Crafter's Cottage
+W +G
  Blacksmith's Cottage
  +W +G
    Blacksmithing Guild
	+W +G
	  Society of Blacksmiths
	  +W +G +C
  Potter's Cottage
  +W +G
    Pottery Guild
	+W +G
	  Society of Potters
	  +W +G +C
  Weaver's Cottage
  +W +G
    Weaving Guild
	+W +G
	  Society of Weavers
	  +W +G +C

## CITY CENTER

Banking House
+W
  Mint
  +W
    Treasury
	+W +X

Grain Exchange
+W +G
-F
  Marketplace
  +W +G
  -F
    Merchant Guild
	+W +G
    -F
	
Brewery
+G +H
  Large Brewery
  +G +H
    Brewing Company
	+G +H

## EDUCATION

School
+E
-F
  College
  +E
  -F
    Trade School
	+E +G +H
	-F
    University
	+E
	-H -F

## SANITATION
Well
+S +H
-F -W
  Troughs
  +S +H
  -F -W
    Canals
	+S +H
    -F -W
  Latrines
  +S +H
  -F -W
    Sewers
	+S
    -F -W
  Public Bath
  +S +H
  -F -W
    Spa Complex
	+S +H
    -F -W
	
## CITY RECRUITMENT

Drill Square
[Unlocks Recruitment]
  Barracks
  [Unlocks Recruitment]
    Armory
	[Unlocks Recruitment]
Bowyer
[Unlocks Recruitment]
  Archery Range
  [Unlocks Recruitment]
    Marksman Range
	[Unlocks Recruitment]
Siege Engineer
[Unlocks Recruitment]
  Siege Workshop
  [Unlocks Recruitment]
    Siege Works
	[Unlocks Recruitment]

## CITY DEFENSE

Fortress [upgraded from Castle]
+D +I +R +A [Unlocks Recruitment]
-F -W
  Citadel
  +D +I +R +A [Unlocks Recruitment]
  -F -W

## REGION INFRASTRUCTURE

Roads
+M +G
  Cobbled Roads
  +M +G  
    Metalled Roads
	+M +G

Peasant Farms
[+20% F]
  Tenant Farms
  [+20% F]
    Great Estates
	[+20% F]

## TOWN DEFENSE

Town Watch
+D +A
  Tower House
  +D +A

## SALT DEPOSIT

Salt Works
+S +W +G
-H

Salt Trader
+W +G
-H -S

## IRON VEIN

Iron Mine
+W [-10% UNIT COST in Region]
-H -S

Iron Trader
+W +G
-H

## QUARRY

Quarry
+W [-10% CONSTRUCTION COST in Region]
-H -S

Stone Trader
+W +G
-H -S

## MARKET TOWN

Grain Exchange
+W +G
-F
  Marketplace
  +W +G
  -F
    Merchant Guild
	+W +G
	-F

Rest Stop
+H +W +G
-F -S
  Country Pub
  +H +W +G
  -F -S
    Coaching Inn
	+H +W +G
    -F -S

## HARBOR TOWN

Fishing Jetty
+F +G
-H -S
  Fishing Wharf
  +F +G
  -H -S
    Fishing Port
	+F +G
	-H -S

Military Jetty
[Unlocks Recruitment] +A
-H -S
  Military Wharf
  [Unlocks Recruitment] +A
  -H -S
    Military Port
	[Unlocks Recruitment] +A
	-H -S


Trading Jetty
+F +G
-H -S
  Trading Wharf
  +F +G
  -H -S
    Trading Port
	+F +G
	-H -S


## FOREST BORDER TOWN

Hunting Cabin
+F +W +H
  Hunting Lodge
  +F +W +H
    Country Mansion
	+F +W +H

Woodcutter's Cabin
[-10% Construction Cost in Region]
  Logging Camp
  [-15% Construction Cost in Region]
    Lumber Camp
	[-20% Construction Cost in Region]

