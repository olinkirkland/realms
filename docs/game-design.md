# Realms Game Design

Realms is a single and multi-player turn-based grand-strategy game taking place in a procedurally generated world with player or AI controlled factions.

The game generates a map with continents and islands to explore, numerous procedurally generated nations, and hundreds of regions containing cities and towns. Controlled regions can be improved and customized with buildings and decrees to guide them towards economic, cultural, or military specializations.

### World Generation Scope

Initially, the game is limited to a map mimicing 0° to 90° real-world latitude and climate reflecting Western Europe. Temperate forests, grasslands, boreal forests, and tundras dominate, but to the south large tracks of savannas and some spots of desert can be found. Factions are designated a culture that defines different faction traits including diplomatic attitude, industrial productivity, and language (which is used to determine initial settlement toponyms).

New adjoining maps are planned to add landmasses west and south of the starting map, but this is a stretch goal.

### Economy

Income sources are comprised of taxes, trade, tribute, and warfare. Players spend this income on developing their empire, recruiting new armies and fleets, military upkeep, and controlling the population.

### Regions

The world of Realms is broken into individual regions comprised of cities and towns. Each region has a city and whatever nation controls that city controls the entire region and its income.

Outside the city, there are towns, farms, mines, ports, and road infrastructure. Each of these structures contributes money to the region's wealth.

### Taxation

Each region has a certain income, but the nation that owns the region doesn't get the whole region's income by their owned regions. In reality, what they get is a percentage of this income in the form of taxes.

Tax policy is managed directly by a nation and is nation-wide. Tax policy can be set to one of five levels, from very low taxes to very high taxes. Each level represents 5% tax on income.

Regions can even be exempted from paying taxes at all, as this will encourage wealth and population growth while removing any unhappiness that results from taxation.

Each region has a city, and every city has a government building. Government buildings can be upgraded several times, with each tier increasing the region's taxation rate.

### Wealth

Tax income is proportional to a region's population, but wealth is the value of a region separate from the region's population. A region's wealth is generated or lost each turn depending on several factors:

1. Industry
2. Ports
3. Roads

Wealth losses result from a nation's taxation policy; the higher the taxes are, the higher the negative modifier for wealth growth in a region. Each level of taxation will return a different modifier that depends on the current wealth rate of change.

Going Bankrupt will decrease the wealth generation by incurring a penalty for several turns, even after getting out of bankruptcy.

### Other Income

The most common source of other income is Protectorate Tribute. Every protectorate a nation has will return a percentage of its total income every turn. So the richer the protectorates, the higher this value will be.

In diplomacy, nations have the option of demanding a payment for several turns as part of a treaty. As long as the treaty is valid, the money a nation has demanded will be added to their income.

### Income by Warfare

Raiding a trade route by parking a raiding army or fleet on it returns 50% of the value of the trade route to the raider, modified by the army/fleet size, and decreases the value of the trade route.

Sacking a city or town returns a high percentage of its value (40%) while razing it returns a low percentage of its value (5%).

### Trade, Trade Partners, and Trade Routes

A nation can trade with any nation with a shared border. If a nation has a port, they can also trade with any nation that has ports even if they are on the other side of the world.

When a nation forms a trade agreement with another nation, a trade route will link the two nations capitals together. If there is a direct land route from one nation's capital to its trade partner's capital and all the regions in between are controlled by either nation, then trade will be conducted by land.

The longer two nations have a trade agreement, the more money they will earn from that trade agreement for the same amount of resources. Prolonged trade agreements are encouraged and given a bonus in diplomacy and in the amount the involved nations get out of the trade route.

### Securing Trade

Any hostile navy can blockade a port, which results in a total loss of trade that might have been coming in or out of that port.

Raiding is performed on trade routes on either land trade routes or naval trade routes and takes some percentage of the value of the trade route.

### Trade Resources and Trade Nodes

There are several types of resources. All of these can be acquired by either controlling regions that produce them.
Some building and unit types will require a specific resource.

Most resource plots will allow one of two resource-harvesting towns to be built.

Mineral resources are scattered throughout the map, and can be extracted through mines. These mines will increase the taxable income generated by a region, and they can be upgraded to return more income. However, upgrading mines will lower happiness. Wood Camps are similar to mines and can also be constructed in limited areas around the map.

### Town and Port Growth

Industrial structures, schools, cultural buildings, and ports are all constructed in towns. Regions contain underdeveloped villages that grow according to global food. When a village becomes an underdeveloped village becomes a town, it can be upgraded. Taxation Policy affects population and town growth negatively.

### Town and Port Wealth

Town wealth rate of change depends on starting wealth of the town, the type of structure built, and the technologies that have been researched (some of them affect town wealth directly).

### Industrialization

Industry takes an important role in increasing a regions' income. There are three types of industrial buildings: Metal Works, Weavers, and Pottery. Industrial buildings will add a constant income that contributes to a region's taxable income. This income depends on the type of industrial building. Happiness is negatively affected by industrial buildings.

### Farming

Farming increases population growth and contributes to the taxable income of a region. Farms can be upgraded, and each tier gives a higher boost to population growth and will return a higher income to its region. One important effect of population growth is that it prompts villages' growth into towns and ports that can be developed into industrial, commercial, or cultural centers.

The income generated by a farm depends on its upgrade and yield. There are low yield farms all the way to Abundant yield farms. The higher the yield, the higher the income.

### Roads

Roads connect regions together, and connect towns and ports with the capital of the region. Roads increase the movement speed of armies and agents when used. They also increase the wealth generated in the region.

### Research

The tech tree is categorized into three trees.

Pursuing the Military tree allows a nation to upgrade its military facilities and recruit better units.
Pursuing the Industry tree allows a nation to build bigger farms and upgrade industrial and commercial centers.
Pursuing the Culture tree allows a nation to unlock faction wide bonuses and effects.

### Family Tree
TBD

### Ministers and Government
TBD

### Army and Navy Upkeep
Upkeep is a recurring cost that has to be paid every turn to soldiers or they will desert.

### Bankruptcy

Bankruptcy occurs when a nation's expenditures are bigger than its income.

The first visible effect of Bankruptcy is army desertion.

The other factor is that Bankruptcy will introduce a rather high penalty on the wealth growth in the bankrupt nation's capital region. As discussed earlier, wealth and wealth growth are necessary to increase taxable income over time.
