package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;
    import com.woodruff.CubicBezier;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.filters.GlowFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;

    import generation.Biome;
    import generation.City;
    import generation.Civilization;
    import generation.Ecosystem;
    import generation.Geography;
    import generation.Names;
    import generation.towns.Town;

    import graph.Cell;
    import graph.Corner;
    import graph.Edge;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Map extends UIComponent {
        public static var NUM_POINTS:int = 25000;
        public static var SEA_LEVEL:Number = .2;
        public static var MOUNTAIN_ELEVATION:Number = .9;
        public static var MOUNTAIN_ELEVATION_ADJACENT:Number = .85;

        public var masterSeed:int;

        // Map Storage
        public var points:Vector.<Point>;
        public var cells:Vector.<Cell>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;
        public var borders:Vector.<Cell>;

        // Managers
        private var geo:Geography;
        private var civ:Civilization;
        private var names:Names;

        // Layers
        private var layers:Array;

        private var oceanLayer:MovieClip = new MovieClip();
        private var terrainLayer:MovieClip = new MovieClip();
        private var coastlinesLayer:MovieClip = new MovieClip();
        private var riversLayer:MovieClip = new MovieClip();
        private var forestsLayer:MovieClip = new MovieClip();
        private var mountainsLayer:MovieClip = new MovieClip();
        private var reliefLayer:MovieClip = new MovieClip();
        private var roadsLayer:MovieClip = new MovieClip();
        private var regionsLayer:MovieClip = new MovieClip();
        private var elevationLayer:MovieClip = new MovieClip();
        private var temperatureLayer:MovieClip = new MovieClip();
        private var outlinesLayer:MovieClip = new MovieClip();

        // Toggles
        public var drawOcean:Boolean = true;
        public var drawTerrain:Boolean = false;
        public var drawCoastlines:Boolean = false;
        public var drawRivers:Boolean = false;
        public var drawForests:Boolean = false;
        public var drawMountains:Boolean = false;
        public var drawCities:Boolean = false;
        public var drawRoads:Boolean = false;
        public var drawRegions:Boolean = false;
        public var drawElevation:Boolean = false;
        public var drawTemperature:Boolean = false;
        public var drawOutlines:Boolean = false;


        // Miscellaneous
        private var staticMode:Bitmap;
        public static var MAP_PROGRESS:String = "mapProgress";

        public function Map() {
            // Initialize Singletons
            geo = Geography.getInstance();
            civ = Civilization.getInstance();
            names = Names.getInstance();

            // Add layers
            layers = [
                oceanLayer,
                terrainLayer,
                coastlinesLayer,
                riversLayer,
                forestsLayer,
                mountainsLayer,
                reliefLayer,
                regionsLayer,
                roadsLayer,
                elevationLayer,
                temperatureLayer,
                outlinesLayer
            ];

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            progress(0, "Preparing points");

            setTimeout(tryToLoadPoints, 500);

            addEventListener(MouseEvent.CLICK, onClick);
        }

        override protected function createChildren():void {
            super.createChildren();

            staticMode = new Bitmap();
            addChild(staticMode);

            for each (var layer:MovieClip in layers) {
                layer.cacheAsBitmap = true;
                addChild(layer);
            }
        }

        private function tryToLoadPoints():void {
            // Does the points file exist?
            if (Util.isAir()) {
                points = AirOnlyUtil.loadPointsFromFile();

                if (!points)
                    generatePoints();

                build();
            } else {
                // Running in web
                generatePoints();
            }

            start();
        }

        private function generatePoints():void {
            // Generate points and save them
            trace("Generating new points ...");
            pickRandomPoints();
            build();
            trace("Relaxing (1/3)");
            relaxPoints();
            trace("Relaxing (2/3)");
            relaxPoints();
            trace("Relaxing (3/3)");
            relaxPoints();

            if (Util.isAir()) {
                AirOnlyUtil.savePointsToFile(points);
            }
        }

        private function progress(percent:Number, message:String):void {
            this.dispatchEvent(new PayloadEvent(MAP_PROGRESS, {percent: percent, message: message}, true));
        }

        public function start(seed:Number = 1):void {
            // Set map seed
            this.masterSeed = seed;

            reset();

            var tasks:Array = [{f: generateHeightMap, m: "Height map"},
                {f: smoothHeightMap, m: "Smoothing"},
                {f: determineOceanLandsAndLakes, m: "Oceans and lakes"},
                {f: calculateTemperature, m: "Temperature"},
                {f: calculateMoisture, m: "Moisture"},
                {f: determineRivers, m: "Rivers"},
                {f: determineBiomes, m: "Biomes"},
                {f: determineCities, m: "Cities"},
                {f: determineRegions, m: "Regions"},
                {f: analyzeRegionsAndDetermineNames, m: "Analyze"},
                {f: determineResources, m: "Resources"},
                {f: determineRoads, m: "Roads"},
                {f: determineTowns, m: "Towns"},
//                {f: determineSeaRoutes, m: "Sea routes"},
                {f: draw, m: "Drawing"}];

            progress(0, tasks[0].m);
            setTimeout(performTask, 100, 0);

            function performTask(i:int):void {
                var timeStarted:Number = new Date().time;

                tasks[i].f();

                trace(tasks[i].m + " (" + ((new Date().time - timeStarted) / 1000).toFixed(2) + "s)");

                i++;

                if (i > tasks.length - 1) {
                    progress(1, "");
                } else {
                    progress(i / tasks.length, tasks[i].m);
                    setTimeout(performTask, 100, i);
                }
            }
        }

        private function generateHeightMap():void {
            // Initially sort cells and their neighbors
            cells.sort(Sort.sortByIndex);
            for each (var cell:Cell in cells)
                cell.neighbors.sort(Sort.sortByIndex);


            // Generate a height map
            var rand:Rand = new Rand(masterSeed);

            var w:Number = width / 2;
            var h:Number = height / 2;

            // Add mountain
            placeMountain(cellFromDistribution(0), .8, .95, .2);

            // Add hills
            for (var i:int = 0; i < 30; i++)
                placeHill(cellFromDistribution(.25), rand.between(.5, .8), rand.between(.95, .99), rand.between(.1, .2));

            // Add big islands further out
            for (i = 0; i < 3; i++)
                placeHill(cellFromDistribution(.3), rand.between(.4, .6), rand.between(.96, .99), rand.between(.1, .3));

            // Add some island clusters
            for (i = 0; i < 3; i++) {
                var centroid:Point = cellFromDistribution(.3).point;
                for (var j:int = 0; j < rand.between(5, 7); j++) {
                    var radius:Number = rand.between(0, 200);
                    var angle:Number = rand.next() * Math.PI * 2;
                    var point:Point = new Point(centroid.x + Math.cos(angle) * radius, centroid.y + Math.sin(angle) * radius);
                    placeHill(getCellClosestToPoint(point), rand.between(.25, .4), rand.between(.6, .9), rand.between(.1, .2));
                }
            }

            // Add pits
            for (i = 0; i < 15; i++)
                placePit(cellFromDistribution(.35), rand.between(.2, .7), rand.between(.8, .95), rand.between(0, .2));

            // Subtract .05 from land cells
            addToLandCells(-.05);

            // Multiply land cells by .9
            multiplyLandCellsBy(.9);

            function cellFromDistribution(distribution:Number):Cell {
                // 0 is map cell
                // 1 is map border
                var dw:Number = distribution * width;
                var dh:Number = distribution * height;
                var px:Number = w + ((rand.next() * 2 * dw) - dw);
                var py:Number = h + ((rand.next() * 2 * dh) - dh);

                return getCellClosestToPoint(new Point(px, py));
            }

            function addToLandCells(value:Number):void {
                for each (cell in cells)
                    if (cell.elevation > SEA_LEVEL)
                        cell.elevation += value;
            }

            function multiplyLandCellsBy(value:Number):void {
                for each (cell in cells)
                    if (cell.elevation > SEA_LEVEL)
                        cell.elevation *= value;
            }

            function placeMountain(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

                // Can only be placed once, at the beginning
                var queue:Array = [];
                start.elevation += elevation;
                if (start.elevation > 1)
                    start.elevation = 1;
                start.used = true;
                queue.push(start);

                for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                    elevation = (queue[i] as Cell).elevation * radius;
                    for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                        if (!neighbor.used) {
                            var mod:Number = (rand.next() * sharpness) + 1.1 - sharpness;
                            if (sharpness == 0)
                                mod = 1;

                            neighbor.elevation += elevation * mod;

                            if (neighbor.elevation > 1)
                                neighbor.elevation = 1;

                            neighbor.used = true;
                            queue.push(neighbor);
                        }
                    }
                }

                unuseCells();
            }

            function placeHill(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

                var queue:Array = [];
                start.elevation += elevation;
                if (start.elevation > 1)
                    start.elevation = 1;

                start.used = true;
                queue.push(start);

                for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                    elevation *= radius;
                    for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                        if (!neighbor.used) {
                            var mod:Number = sharpness > 0 ? rand.next() * sharpness + 1.1 - sharpness : 1;
                            neighbor.elevation += elevation * mod;

                            if (neighbor.elevation > 1)
                                neighbor.elevation = 1;

                            neighbor.used = true;
                            queue.push(neighbor);
                        }
                    }
                }

                unuseCells();
            }

            function placePit(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

                var queue:Array = [];
                elevation *= -1;
                start.elevation += elevation;
                if (start.elevation < 0)
                    start.elevation = 0;

                start.used = true;
                queue.push(start);

                for (var i:int = 0; i < queue.length && elevation < SEA_LEVEL - .01; i++) {
                    elevation *= radius;
                    for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                        if (!neighbor.used) {
                            var mod:Number = sharpness > 0 ? rand.next() * sharpness + 1.1 - sharpness : 1;
                            neighbor.elevation += elevation * mod;

                            if (neighbor.elevation < 0)
                                neighbor.elevation = 0;

                            neighbor.used = true;
                            queue.push(neighbor);
                        }
                    }
                }

                unuseCells();
            }
        }

        private function smoothHeightMap():void {
            cells.sort(Sort.sortByIndex);

            var depressions:int;
            do {
                depressions = 0;
                for each (var cell:Cell in cells) {

                    // Is it a depression?
                    if (cell.neighbors.length > 0) {
                        var d:Boolean = cell.elevation >= SEA_LEVEL;
                        for each (var neighbor:Cell in cell.neighbors) {
                            if (neighbor.elevation < cell.elevation)
                                d = false;
                        }
                    }

                    if (d) {
                        // If it's a depression, raise its elevation a little and increment the depression count
                        depressions++;
                        cell.elevation += .1;
                    }
                }
            } while (depressions > 0);
        }


        private function calculateTemperature():void {
            for each (var cell:Cell in cells) {
                // Mapping 0 to 90 realLatitude for this section of the world
                cell.latitude = 1 - (cell.point.y / height);
                cell.realLatitude = Util.round(cell.latitude * 90, 2);
                var temperature:Number = 1 - cell.latitude;

                // Consider elevation in the temperature (higher places are colder)
                cell.temperature = temperature - (cell.elevation * .3);
                if (cell.temperature < 0)
                    cell.temperature = 0;
                if (cell.temperature > 1)
                    cell.temperature = 1;

                cell.realTemperature = Util.round(-10 + (cell.temperature * 40), 2);
            }
        }

        private function calculateMoisture():void {
            for each (var cell:Cell in cells) {
                var m:Number = 0;

                for each (var neighbor:Cell in cell.neighbors)
                    m += neighbor.elevation;
                m /= cell.neighbors.length;

                cell.moisture = m;
                cell.precipitation = Util.round(200 + (cell.moisture * 1800), 2);
            }
        }

        private function determineRivers():void {
            // Create rivers
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                // Set the flux on all land cells first
                for each (var cell:Cell in land.cells)
                    cell.flux = cell.moisture;

                land.cells.sort(Sort.sortByHighestElevation);
                for each (cell in land.cells) {
                    // Pour to the lowest neighbor
                    cell.neighbors.sort(Sort.sortByLowestElevation);
                    pour(cell, cell.neighbors[0]);
                }
            }

            // Register rivers as freshwater biomes
            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER)) {
                river.centroid = river.cells[int(river.cells.length / 2)].point;
                var freshWater:String = geo.registerFeature(Biome.FRESH_WATER);
                for each (cell in river.cells)
                    geo.addCellToFeature(cell, freshWater);
            }

            unuseCells();

            function pour(c:Cell, t:Cell):void {
                t.flux += c.flux;
                if (c.flux > 10) {
                    var river:String;
                    if (c.hasFeatureType(Geography.RIVER)) {
                        // Extend river
                        var rivers:Object = c.getFeaturesByType(Geography.RIVER);
                        var riverCount:int = 0;
                        for (var v:String in rivers) {
                            riverCount++;
                            // Pick the longest river to continue
                            if (!river || rivers[v].cells.length > rivers[river].cells.length)
                                river = v;
                        }

                        geo.addCellToFeature(t, river);

                        if (!t.hasFeatureType(Geography.OCEAN) && !t.hasFeatureType(Geography.LAKE) && riverCount > 1) {
                            var confluence:String = geo.registerFeature(Geography.CONFLUENCE);
                            geo.addCellToFeature(t, confluence);
                        }
                    } else {
                        // Start new river
                        river = geo.registerFeature(Geography.RIVER);
                        geo.addCellToFeature(c, river);
                        geo.addCellToFeature(t, river);
                    }

                    if (t.hasFeatureType(Geography.OCEAN) || t.hasFeatureType(Geography.LAKE)) {
                        var estuary:String = geo.registerFeature(Geography.ESTUARY);
                        geo.addCellToFeature(c, estuary);
                        var water:Object = {};
                        // An estuary can empty into an ocean or a lake, but not into both
                        if (t.hasFeatureType(Geography.OCEAN))
                            water = t.getFeaturesByType(Geography.OCEAN);
                        if (t.hasFeatureType(Geography.LAKE))
                            water = t.getFeaturesByType(Geography.LAKE);

                        // There can only be one lake or ocean feature referenced in the estuary's target
                        for each (var target:String in water)
                            break;

                        var feature:Object = geo.features[estuary];
                        feature.target = target;
                    }
                }
            }
        }

        private function determineBiomes():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var landCells:Vector.<Cell> = land.cells.concat();
                var queue:Array = [];
                while (landCells.length > 0) {
                    var start:Cell = landCells[0];
                    start.used = true;

                    // Pick a starting biome
                    var currentBiome:String = Biome.determineBiome(start);
                    var currentFeature:String = geo.registerFeature(currentBiome);
                    geo.addCellToFeature(start, currentFeature);
                    start.biome = currentFeature;
                    start.biomeType = currentBiome;

                    // Fill touching cells
                    queue.push(start);
                    var cell:Cell;
                    while (queue.length > 0) {
                        cell = queue[0];
                        queue.shift();
                        for each (var neighbor:Cell in cell.neighbors) {
                            var d:Boolean = Biome.determineBiome(neighbor) == currentBiome;
                            if (!neighbor.used && land.cells.indexOf(neighbor) >= 0 && d) {
                                geo.addCellToFeature(neighbor, currentFeature);
                                neighbor.biome = currentFeature;
                                neighbor.biomeType = currentBiome;
                                queue.push(neighbor);
                                neighbor.used = true;
                            }
                        }
                    }

                    landCells = new Vector.<Cell>();
                    for each (cell in land.cells)
                        if (!cell.used)
                            landCells.push(cell);
                }
            }

            unuseCells();

            // Determine glades
            for each (var grassland:Object in geo.getFeaturesByType(Biome.GRASSLAND)) {
                // isGlade is positive for grasslands as long as they are small and entirely surrounded by forest
                var isGlade:Boolean = grassland.cells.length < 10;
                for each (cell in grassland.cells) {
                    for each (neighbor in cell.neighbors)
                        if (!neighbor.hasFeatureType(Biome.GRASSLAND) && !neighbor.hasFeatureType(Biome.TEMPERATE_FOREST))
                            isGlade = false;
                }
                if (isGlade) {
                    var glade:String = geo.registerFeature(Geography.GLADE);
                    for each (cell in grassland.cells)
                        geo.addCellToFeature(cell, glade);
                }
            }

            // Determine sheltered havens
            for each(land in geo.getFeaturesByType(Geography.LAND)) {
                // Get coastal cells
                for each (cell in land.cells) {
                    for each (var edge:Edge in cell.edges) {
                        if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                            if (!edge.d0.hasFeatureType(Geography.LAND) || !edge.d1.hasFeatureType(Geography.LAND)) {
                                // It's coastal
                                var coastal:Cell = !edge.d0.hasFeatureType(Geography.LAND) ? edge.d1 : edge.d0;
                                coastal.coastal = true;
                                var oceanNeighborCount:int = 0;
                                for each (neighbor in coastal.neighbors) {
                                    if (neighbor.hasFeatureType(Geography.OCEAN))
                                        oceanNeighborCount++;
                                }

                                if (oceanNeighborCount == 1) {
                                    var haven:String = geo.registerFeature(Geography.HAVEN);
                                    geo.addCellToFeature(coastal, haven);
                                }
                            }
                        }
                    }
                }
            }

            describeBiomes();

            function describeBiomes():void {
                // Link biomes that are nearby and similar type
                for each (var biomeType:String in Biome.list) {
                    for each (var biome:Object in geo.getFeaturesByType(biomeType)) {
                        // First, determine the center point of the biome
                        var avgX:Number = 0;
                        var avgY:Number = 0;

                        for each (var cell:Cell in biome.cells) {
                            avgX += cell.point.x;
                            avgY += cell.point.y;
                        }

                        biome.centroid = new Point(avgX /= biome.cells.length, avgY /= biome.cells.length);
                        biome.influence = Math.min(biome.cells.length, 300);
                        biome.linked = [];
                    }

                    var biomes:Array = [];
                    for each (biome in geo.getFeaturesByType(biomeType))
                        biomes.push(biome);
                    biomes.sort(Sort.sortByCellCount);

                    for each (biome in biomes) {
                        for each (var targetBiome:Object in geo.getFeaturesByType(biomeType)) {
                            // Non-tiny biomes (> 10 cells) can link to other biomes of the same type to share flora/fauna
                            // Linked biomes must be near each other - the permitted distance is calculated using the biomes' relative sizes
                            if (biome != targetBiome && Util.getDistanceBetweenTwoPoints(biome.centroid, targetBiome.centroid) < biome.influence && biome.cells.length > 10 && biome.linked.indexOf(targetBiome) < 0 && biome.cells.length > targetBiome.cells.length) {
                                biome.linked.push(targetBiome);
                            }
                        }
                    }

                    for each (biome in biomes)
                        biome.ecosystem = new Ecosystem(biome);

                    for each (biome in biomes)
                        biome.ecosystem.spreadProperties();
                }
            }
        }

        private function determineCities():void {
            determineStaticCityDesirability();

            var i:int = 0;
            for (var i:int = 0; i < 120; i++) {
                determineCityDesirability();

                civ.registerCity(cells[0]);
                i++;
            }
        }

        private function determineRegions():void {
            // If there are no cities on a land mass, add one to a haven or a random place
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var hasCity:Boolean = false;
                for each (var cell:Cell in land.cells) {
                    if (cell.city) {
                        hasCity = true;
                        break;
                    }
                }

                if (!hasCity) {
                    // Add a city to the landmass
                    for each (cell in land.cells) {
                        var haven:Cell = land.cells[0];
                        if (cell.hasFeatureType(Geography.HAVEN)) {
                            haven = cell;
                            break;
                        }
                    }

                    civ.registerCity(haven);
                }
            }

            // Sort cities
            var cities:Array = [];
            for each (var s:City in civ.cities)
                cities.push(s);

            // Sort by a unique value - point should do
            cities.sort(Sort.sortByCellIndex);

            for each (var city:City in cities) {
                var start:Cell = city.cell;
                // Define region
                var regionId:String = civ.registerRegion();

                var r:Rand = new Rand(1);
                civ.addCellToRegion(start, regionId, 200 + int(r.next() * 5) * 4);

                for each (land in start.getFeaturesByType(Geography.LAND))
                    break;

                civ.regions[regionId].land = land;
                civ.regions[regionId].city = city;

                start.used = true;

                var queue:Array = [start];

                while (queue.length > 0) {
                    cell = queue.shift();

                    if (cell.regionInfluence > 0) {
                        for each (var neighbor:Cell in cell.neighbors) {
                            // What's the cost of adding this cell to the region?
                            var cost:int = 1;
                            if (neighbor.hasFeatureType(Geography.OCEAN))
                                cost = 999;
                            if (neighbor.hasFeatureType(Biome.MOUNTAIN))
                                cost = 20;
                            if ((cell.hasFeatureType(Biome.TUNDRA) || cell.hasFeatureType(Biome.GRASSLAND) || cell.hasFeatureType(Biome.SAVANNA)) && (neighbor.hasFeatureType(Biome.BOREAL_FOREST) || neighbor.hasFeatureType(Biome.TEMPERATE_FOREST) || neighbor.hasFeatureType(Biome.RAIN_FOREST)))
                                cost = 10;
                            if (neighbor.hasFeatureType(Geography.RIVER) || neighbor.hasFeatureType(Geography.LAKE))
                                cost = 20;

                            var influence:int = cell.regionInfluence - cost;

                            if (!neighbor.used && neighbor.regionInfluence < influence) {
                                // Use ocean tiles, but don't add them to the region
                                if (!neighbor.hasFeatureType(Geography.OCEAN))
                                    civ.addCellToRegion(neighbor, regionId, influence);
                                else
                                    neighbor.regionInfluence = influence;

                                queue.push(neighbor);
                                neighbor.used = true;
                            }
                        }
                    }
                }

                unuseCells();
            }

            for each (var region:Object in civ.regions) {
                // Determine the center point of the region
                var avgX:Number = 0;
                var avgY:Number = 0;

                for each (cell in region.cells) {
                    avgX += cell.point.x;
                    avgY += cell.point.y;
                }

                region.centroid = new Point(avgX /= region.cells.length, avgY /= region.cells.length);

                // Lands contain a list of their contained regions
                region.land.regions.push(region);

                // Regions contain a list of their border points
                var regionBorderEdges:Array = [];
                for each (var cell:Cell in region.cells)
                    for each (var edge:Edge in cell.edges)
                        if (edge.v0 && edge.v1 && edge.d0 && edge.d1)
                            if (edge.d0.region != region.id || edge.d1.region != region.id)
                                regionBorderEdges.push(edge);

                var regionBorderPoints:Array = [];
                var simpleBorderPoints:Array = [];
                var firstEdge:Edge = regionBorderEdges.shift();
                regionBorderPoints.push.apply(this, firstEdge.noisyPoints);
                simpleBorderPoints.push.apply(this, [firstEdge.v0.point, firstEdge.v1.point]);

                while (regionBorderEdges.length > 0) {
                    var current:Point = regionBorderPoints[regionBorderPoints.length - 1];
                    for (var i:int = 0; i < regionBorderEdges.length; i++) {
                        edge = regionBorderEdges[i];
                        if (edge.v0.point.equals(current)) {
                            regionBorderPoints.push.apply(this, edge.noisyPoints);
                            regionBorderPoints.push(edge.v1.point);
                            simpleBorderPoints.push.apply(this, [edge.v0.point, edge.v1.point]);
                            regionBorderEdges.removeAt(i);
                            break;
                        } else if (edge.v1.point.equals(current)) {
                            regionBorderPoints.push.apply(this, edge.noisyPoints.reverse());
                            regionBorderPoints.push(edge.v0.point);
                            simpleBorderPoints.push.apply(this, [edge.v1.point, edge.v0.point]);
                            regionBorderEdges.removeAt(i);
                            break;
                        }
                    }
                }

                region.borderPoints = regionBorderPoints;
                region.simpleBorderPoints = simpleBorderPoints;
            }
        }

        private function analyzeRegionsAndDetermineNames():void {
            names.nameRegions(civ.regions);
            names.nameCities(civ.cities);
            names.nameTowns(civ.towns);
        }

        private function determineResources():void {
            // Determine resource points
            // Determine minerals
            var resourceTypes:Array = [{type: Geography.STONE, count: 10},
                {type: Geography.SALT, count: 10},
                {type: Geography.IRON, count: 5}];
            for each (var resourceType:Object in resourceTypes) {
                // Determine static resource desirability
                determineStaticResourceDesirability(resourceType.type);

                // Reset all resource 'used' flags
                for each (var r:String in resourceTypes)
                    for each (var resource:Object in geo.getFeaturesByType(r))
                        resource.used = false;

                for (var i:int = 0; i < resourceType.count; i++) {
                    determineResourceDesirability();

                    if (cells[0].desirability > 0) {
                        var feature:String = geo.registerFeature(resourceType.type);
                        geo.addCellToFeature(cells[0], feature);
                    }
                }
            }
        }

        private function determineStaticResourceDesirability(resourceType:String):void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                for each (var cell:Cell in land.cells) {
                    cell.desirability = 0;
                    for each (var neighbor:Cell in cell.neighbors) {
                        // All minerals are found near mountains
                        if (neighbor.hasFeatureType(Biome.MOUNTAIN)) {
                            cell.desirability = 5;
                            break;
                        }

                        // Salt is also found near lakes
                        if (resourceType == Geography.SALT && neighbor.hasFeatureType(Geography.LAKE)) {
                            cell.desirability = 5;
                            break;
                        }
                    }

                    // Don't allow minerals to spawn in mountains
                    // Resource points will be used to spawn towns, and towns shouldn't generally exist up in mountains
                    if (cell.hasFeatureType(Biome.MOUNTAIN))
                        cell.desirability = 0;
                }
            }
            for each (var city:City in civ.cities) {
                city.cell.desirability = 0;
                for each (neighbor in city.cell.neighbors)
                    neighbor.desirability = 0;
            }
        }

        private function determineResourceDesirability():void {
            var resourceTypes:Array = [Geography.STONE, Geography.SALT, Geography.IRON];
            for each (var resourceType:String in resourceTypes) {
                for each (var resource:Object in geo.getFeaturesByType(resourceType)) {
                    var queue:Array = [];
                    var undesirability:Number = 20;
                    var radius:Number = .8;

                    resource.cells[0].used = true;
                    resource.cells[0].desirability = 0;
                    queue.push(resource.cells[0]);

                    for (var i:int = 0; i < queue.length && undesirability > 0.01; i++) {
                        undesirability *= radius;
                        for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                            if (!neighbor.used) {
                                neighbor.desirability -= undesirability;
                                if (neighbor.desirability < 0)
                                    neighbor.desirability = 0;

                                neighbor.used = true;
                                queue.push(neighbor);
                            }
                        }
                    }

                    unuseCells();
                    resource.used = true;
                }
            }

            cells.sort(Sort.sortByDesirability);
        }

        private function determineRoads():void {
            // Determine roads
            var cities:Array = [];
            for each (var city:City in civ.cities)
                cities.push(city);

            cities.sort(Sort.sortByCellIndex);

            var cityPoints:Vector.<Point> = new Vector.<Point>();
            for each (city in cities)
                cityPoints.push(city.point);

            // Create a voronoi diagram of the cities to determine city neighbors
            var voronoi:Voronoi = new Voronoi(cityPoints, null, new Rectangle(0, 0, width, height));
            for each (city in cities)
                voronoi.region(city.point);

            // Initially determine costs
            for each (var cell:Cell in cells)
                cell.determineCost();

            for each (city in cities) {
                var neighborPoints:Vector.<Point> = voronoi.neighborSitesForSite(city.point);
                for each (var neighborPoint:Point in neighborPoints) {
                    for each (var neighborCity:City in cities) {
                        if (neighborCity.point == neighborPoint) {
                            city.neighbors.push(neighborCity);
                            // From city.cell to neighbor.cell
                            var queue:Vector.<Cell> = new Vector.<Cell>();
                            queue.push(city.cell);
                            city.cell.costSoFar = 0;

                            while (queue.length > 0) {
                                var current:Cell = queue.shift();

                                // Reached the destination
                                if (current.index == neighborCity.cell.index)
                                    break;

                                // Loop through queue
                                for each (var next:Cell in current.neighbors) {
                                    // Each queue item's neighbors
                                    var nextCost:int = next.cost;
                                    var newCost:int = current.costSoFar + nextCost;
                                    if (!next.used || newCost < next.costSoFar) {
                                        next.used = true;
                                        next.costSoFar = newCost;
                                        next.cameFrom = current;
                                        next.priority = newCost;
                                        // Place 'next' in the queue
                                        if (newCost < 1000) {
                                            var queueLength:int = queue.length;
                                            if (queueLength > 0) {
                                                for (var i:int = 0; i < queueLength; i++)
                                                    if (queue[i].priority > next.priority)
                                                        break;
                                                queue.insertAt(i, next);
                                            } else {
                                                // Just add it
                                                queue.push(next);
                                            }
                                        }
                                    }
                                }
                            }

                            unuseCells();

                            var roadCells:Vector.<Cell> = new Vector.<Cell>();
                            cell = neighborCity.cell;
                            var lastCell:Cell;

                            var cost:int = 0;
                            for (i = 0; i < 1000; i++) {
                                roadCells.push(cell);
                                // Reached the city
                                if (cell == city.cell)
                                    break;
                                // Reached any road that's not on neighborCity
                                if (cell.road > 0 && cell != neighborCity.cell) {

                                    // If the last cell visited is neighborCity
                                    // and neighborCity had a road, clear the roadCells
                                    if (lastCell && lastCell.road > 0 && lastCell == neighborCity.cell)
                                        roadCells = new Vector.<Cell>();


                                    break;
                                }

                                lastCell = cell;
                                cell = cell.cameFrom;

                                if (!cell)
                                    break;

                                cost += cell.costSoFar;
                            }

                            // Create the road
                            if (cost < 200 && roadCells.length > 0) {
                                var road:String = civ.registerRoad(neighborCity.cell, cell);
                                civ.addCellsToRoad(roadCells, road);
                                for each (cell in roadCells) {

                                    if (!cell.crossroad && cell.road > 0 && !cell.city)
                                        civ.registerCrossroad(cell);

                                    cell.road++;
                                    cell.determineCost();
                                }
                            }

                            // Clear cameFrom property in all cells
                            for each (cell in cells)
                                cell.cameFrom = null;
                        }
                    }
                }
            }
        }

        private function determineTowns():void {
            // Each region should have a number of towns depending on its size
            // Start by adding stone, salt, and iron resource points as towns
            for each (var region:Object in civ.regions) {
                region.towns = {};
                for each (var cell:Cell in region.cells) {
                    if (cell.hasFeatureType(Geography.STONE)) {
                        // Add stone quarry town
                        civ.registerTown(cell, Town.STONE);
                    } else if (cell.hasFeatureType(Geography.SALT)) {
                        // Add salt mining town
                        civ.registerTown(cell, Town.SALT);
                    } else if (cell.hasFeatureType(Geography.IRON)) {
                        // Add iron mining town
                        civ.registerTown(cell, Town.IRON);
                    }
                }
            }

            // Each crossroad should have a trade town
            var distanceToNearestTownOrCity:Number;
            for each (var crossroad:Object in civ.crossroads) {
                // Can't be too close to other towns and cities
                distanceToNearestTownOrCity = Number.POSITIVE_INFINITY;
                for each (var town:Town in civ.towns) {
                    var d:Number = Util.getDistanceBetweenTwoPoints(town.cell.point, crossroad.cell.point);
                    if (!distanceToNearestTownOrCity || d < distanceToNearestTownOrCity)
                        distanceToNearestTownOrCity = d;
                }

                for each (var city:City in civ.cities) {
                    d = Util.getDistanceBetweenTwoPoints(city.cell.point, crossroad.cell.point);
                    if (d < distanceToNearestTownOrCity)
                        distanceToNearestTownOrCity = d;
                }

                // Trading towns should be at least 30 pixels away from other towns or cities
                if (distanceToNearestTownOrCity > 30)
                    civ.registerTown(crossroad.cell, Town.TRADE);
            }

            // For each region, calculate how many towns it contains and how many it "should" (based on size)
            // If it's large, add a single town (either a Fishing town or a Logging town, whichever's more reasonable)
            for each (var region:Object in civ.regions) {
                var townCount:int = 0;
                var optimalFishingTownSpots:Array = [];
                var optimalLoggingTownSpots:Array = [];
                for each (var cell:Cell in region.cells) {
                    if (cell.town)
                        townCount++;
                    else if (!cell.city) {
                        if (cell.hasFeatureType(Geography.HAVEN))
                            optimalFishingTownSpots.push(cell);
                        else if (cell.hasFeatureType(Biome.TUNDRA) || cell.hasFeatureType(Biome.GRASSLAND) || cell.hasFeatureType(Biome.SAVANNA)) {
                            for each (var neighbor:Cell in cell.neighbors) {
                                if (neighbor.hasFeatureType(Biome.BOREAL_FOREST) || neighbor.hasFeatureType(Biome.TEMPERATE_FOREST) || neighbor.hasFeatureType(Biome.RAIN_FOREST)) {
                                    optimalLoggingTownSpots.push(cell);
                                    break;
                                }
                            }
                        }
                    }
                }

                if (townCount < region.cells.length / 10) {
                    // Add a town
                    // Should it be a Fishing town or a Logging town?
                    var townAdded:Boolean = false;
                    optimalFishingTownSpots.sort(Sort.sortByIndex);
                    optimalLoggingTownSpots.sort(Sort.sortByIndex);
                    if (optimalFishingTownSpots.length > 0) {
                        for each (var optimalFishingTownSpot:Cell in optimalFishingTownSpots) {
                            // Can't be too close to other towns and cities
                            distanceToNearestTownOrCity = Number.POSITIVE_INFINITY;
                            for each (town in civ.towns) {
                                var d:Number = Util.getDistanceBetweenTwoPoints(town.cell.point, optimalFishingTownSpot.point);
                                if (!distanceToNearestTownOrCity || d < distanceToNearestTownOrCity)
                                    distanceToNearestTownOrCity = d;
                            }

                            for each (var city:City in civ.cities) {
                                var d:Number = Util.getDistanceBetweenTwoPoints(city.cell.point, optimalFishingTownSpot.point);
                                if (d < distanceToNearestTownOrCity)
                                    distanceToNearestTownOrCity = d;
                            }

                            // Fishing towns should be at least 30 pixels away from other towns or cities
                            if (distanceToNearestTownOrCity > 30) {
                                civ.registerTown(optimalFishingTownSpot, Town.FISH);
                                townAdded = true;
                                break;
                            }
                        }
                    }

                    if (!townAdded && optimalLoggingTownSpots.length > 0) {
                        for each (var optimalLoggingTownSpot:Cell in optimalLoggingTownSpots) {
                            // Can't be too close to other towns and cities
                            distanceToNearestTownOrCity = Number.POSITIVE_INFINITY;
                            for each (town in civ.towns) {
                                var d:Number = Util.getDistanceBetweenTwoPoints(town.cell.point, optimalLoggingTownSpot.point);
                                if (!distanceToNearestTownOrCity || d < distanceToNearestTownOrCity)
                                    distanceToNearestTownOrCity = d;
                            }

                            for each (var city:City in civ.cities) {
                                var d:Number = Util.getDistanceBetweenTwoPoints(city.cell.point, optimalLoggingTownSpot.point);
                                if (d < distanceToNearestTownOrCity)
                                    distanceToNearestTownOrCity = d;
                            }

                            // Logging towns should be at least 30 pixels away from other towns or cities
                            if (distanceToNearestTownOrCity > 30) {
                                civ.registerTown(optimalLoggingTownSpot, Town.WOOD);
                                break;
                            }
                        }
                    }

                    if (!townAdded) {
                        // todo generic town type here?
                    }
                }
            }
        }


        private function determineSeaRoutes():void {

        }

        private function determineStaticCityDesirability():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                for each (var cell:Cell in land.cells) {
                    cell.desirability = 1;

                    // Biome desirability
                    if (cell.hasFeatureType(Biome.GRASSLAND))
                        cell.desirability += 4;
                    if (cell.hasFeatureType(Biome.TEMPERATE_FOREST))
                        cell.desirability += 3;
                    if (cell.hasFeatureType(Biome.BOREAL_FOREST))
                        cell.desirability += 2;
                    if (cell.hasFeatureType(Biome.TUNDRA))
                        cell.desirability += 1;
                    if (cell.hasFeatureType(Biome.MOUNTAIN))
                        cell.desirability += 1;

                    // River desirability
                    if (cell.hasFeatureType(Geography.ESTUARY) || cell.hasFeatureType(Geography.CONFLUENCE)) {
                        var d:int = Math.sqrt(cell.flux);
                        cell.desirability += 4 + int(d);
                    } else if (cell.hasFeatureType(Geography.RIVER)) {
                        d = Math.sqrt(cell.flux);
                        cell.desirability += int(d);
                    }

                    // Coast desirability
                    if (cell.hasFeatureType(Geography.HAVEN))
                        cell.desirability += 2;
                }
            }

            determineCityDesirability();
        }

        private function determineCityDesirability():void {
            for each (var city:City in civ.cities) {
                if (!city.used) {
                    var queue:Array = [];
                    var undesirability:Number = 20;
                    var radius:Number = .8;

                    city.cell.used = true;
                    city.cell.desirability = 0;
                    queue.push(city.cell);

                    for (var i:int = 0; i < queue.length && undesirability > 0.01; i++) {
                        undesirability *= radius;
                        for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                            if (!neighbor.used) {
                                neighbor.desirability -= undesirability;
                                if (neighbor.desirability < 0)
                                    neighbor.desirability = 0;

                                neighbor.used = true;
                                queue.push(neighbor);
                            }
                        }
                    }

                    unuseCells();
                    city.used = true;
                }
            }

            cells.sort(Sort.sortByDesirability);
        }

        private function determineOceanLandsAndLakes():void {
            var queue:Array = [];

            // Start with a site that is at 0 elevation and is in the upper left
            // Don't pick a border site because they're fucky
            for each (var start:Cell in cells) {
                if (start.elevation == 0 && start.neighbors.length > 0)
                    break;
            }

            var ocean:String = geo.registerFeature(Geography.OCEAN);
            geo.addCellToFeature(start, ocean);
            start.used = true;
            queue.push(start);

            // Define Ocean
            var biome:String = geo.registerFeature(Biome.SALT_WATER);
            while (queue.length > 0) {
                var cell:Cell = queue.shift();
                for each (var neighbor:Cell in cell.neighbors) {
                    if (!neighbor.used && neighbor.elevation < SEA_LEVEL) {
                        geo.addCellToFeature(neighbor, ocean);
                        geo.addCellToFeature(neighbor, biome);
                        queue.push(neighbor);
                        neighbor.used = true;
                    }
                }
            }

            // Override list edges to be part of the Ocean
            for each (cell in borders) {
                geo.addCellToFeature(cell, ocean);
                geo.addCellToFeature(cell, biome);
            }


            // Define Land and Lakes
            var nonOceans:Vector.<Cell> = new Vector.<Cell>();
            for each (cell in cells)
                if (Util.getLengthOfObject(cell.features) == 0)
                    nonOceans.push(cell);

            var currentFeature:String;
            while (nonOceans.length > 0) {
                start = nonOceans[0];

                var lower:Number;
                var upper:Number;

                // If the elevation of the cell is higher than sea level, define it as Land otherwise define it as a Lake
                if (start.elevation >= SEA_LEVEL) {
                    // Define it as land
                    currentFeature = geo.registerFeature(Geography.LAND);
                    biome = null;

                    lower = SEA_LEVEL;
                    upper = Number.POSITIVE_INFINITY;
                } else {
                    // Define it as a lake
                    currentFeature = geo.registerFeature(Geography.LAKE);
                    biome = geo.registerFeature(Biome.FRESH_WATER);

                    lower = Number.NEGATIVE_INFINITY;
                    upper = SEA_LEVEL;
                }

                geo.addCellToFeature(start, currentFeature);
                if (biome)
                    geo.addCellToFeature(start, biome);

                start.used = true;

                // Fill touching Land or Lake cells
                queue.push(start);
                while (queue.length > 0) {
                    cell = queue[0];
                    queue.shift();
                    for each (neighbor in cell.neighbors) {
                        if (!neighbor.used && neighbor.elevation >= lower && neighbor.elevation < upper) {
                            geo.addCellToFeature(neighbor, currentFeature);
                            if (biome)
                                geo.addCellToFeature(neighbor, biome);

                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }

                nonOceans = new Vector.<Cell>();
                for each (cell in cells)
                    if (Util.getLengthOfObject(cell.features) == 0)
                        nonOceans.push(cell);
            }

            unuseCells();

            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var avgX:Number = 0;
                var avgY:Number = 0;

                for each (cell in land.cells) {
                    avgX += cell.point.x;
                    avgY += cell.point.y;
                }

                land.regions = [];

                land.centroid = new Point(avgX /= land.cells.length, avgY /= land.cells.length);
            }
        }

        private function unuseCells():void {
            for each (var cell:Cell in cells) {
                cell.used = false;
            }
        }

        private function relaxPoints():void {
            points = new Vector.<Point>();
            for each (var cell:Cell in cells) {
                var centroid:Point = new Point();
                for each (var corner:Corner in cell.corners) {
                    centroid.x += corner.point.x;
                    centroid.y += corner.point.y;
                }

                centroid.x /= cell.corners.length;
                centroid.y /= cell.corners.length;

                points.push(Point.interpolate(cell.point, centroid, 0.5));
            }

            // Rebuild graph
            build();
        }

        public function getCellClosestToPoint(p:Point):Cell {
            var shortestDistance:Number = Number.POSITIVE_INFINITY;
            var closestCell:Cell;
            var distance:Number;

            for each (var cell:Cell in cells) {
                distance = (cell.point.x - p.x) * (cell.point.x - p.x) + (cell.point.y - p.y) * (cell.point.y - p.y);
                if (distance < shortestDistance) {
                    closestCell = cell;
                    shortestDistance = distance;
                }
            }

            return closestCell;
        }

        public function draw():void {
            /**
             * Main Draw Call
             */

            // Clear all layers
            for each (var layer:MovieClip in layers) {
                while (layer.numChildren > 0)
                    layer.removeChildAt(0);
                layer.graphics.clear();
            }

            // Draw all the layers
            drawOceanLayer();
            drawTerrainLayer();
            drawCoastlinesLayer();
            drawRiversLayer();
            drawForestsLayer();
            drawMountainsLayer();
            drawRegionsLayer();
            drawRoadsLayer();
            drawElevationLayer();
            drawTemperatureLayer();
            drawOutlinesLayer();

            // The show function toggles visibility on and off for specific layers
            show();

            // Make sure it starts live, not static
            staticModeOff();
        }

        private function fillCell(canvas:Graphics, cell:Cell, color:uint):void {
            // Draw a filled cell
            canvas.beginFill(color);
            for each (var edge:Edge in cell.edges) {
                if (edge.v0 && edge.v1) {
                    canvas.moveTo(edge.v0.point.x, edge.v0.point.y);
                    canvas.lineTo(cell.point.x, cell.point.y);
                    canvas.lineTo(edge.v1.point.x, edge.v1.point.y);
                }
            }
            canvas.endFill();
        }

        private function addCellDetail(canvas:Graphics, cell:Cell):void {
            // Add detail to a cell
            var rand:Rand = new Rand(Math.random() * 99);
            var iconDensity:Number = 0;
            var c:Point = new Point(cell.point.x + rand.between(-4, 4), cell.point.y + rand.between(-4, 4));
            var d:Number;

            if (cell.hasFeatureType(Biome.TEMPERATE_FOREST)) {
                iconDensity = .6;

                if (rand.next() > iconDensity)
                    return;

                if (bordersForeignType(cell, Biome.TEMPERATE_FOREST))
                    return;

                canvas.lineStyle(rand.between(1, 1.5), Biome.colors["temperateForest_stroke"], rand.between(.6, 1));
                canvas.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                canvas.curveTo(c.x, c.y - rand.between(1, 5), c.x + d, c.y);
            }

            if (cell.hasFeatureType(Biome.BOREAL_FOREST)) {
                iconDensity = .8;

                if (rand.next() > iconDensity)
                    return;

                canvas.lineStyle(rand.between(.5, 1.5), Biome.colors["borealForest_stroke"], rand.between(.6, 1));
                canvas.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                canvas.lineTo(c.x, c.y - rand.between(1, 3));
                canvas.lineTo(c.x + d, c.y);
            }
        }

        private function bordersForeignType(cell:Cell, type:String):Boolean {
            // Check that the cell isn't bordering any foreign biome types
            for each (var neighbor:Cell in cell.neighbors)
                if (!neighbor.hasFeatureType(type))
                    return true;
            return false;
        }

        private function drawOceanLayer():void {
            /**
             * Draw Ocean
             */

            // Fill in the ocean so the voronoi-bare corners get some ocean
            // Just make a big honking rectangle of salt water
            oceanLayer.graphics.beginFill(Biome.colors[Biome.SALT_WATER]);
            oceanLayer.graphics.drawRect(0, 0, width, height);
        }

        private function drawTerrainLayer():void {
            /**
             * Draw Terrain
             */

            terrainLayer.graphics.lineStyle();
            for each (var biomeType:String in Biome.list) {
                for each (var biome:Object in geo.getFeaturesByType(biomeType)) {
                    for each (var cell:Cell in biome.cells) {
                        fillCell(terrainLayer.graphics, cell, Biome.colors[biomeType]);
                        cell.terrainColor = Biome.colors[biomeType];
                    }
                }
            }

            // Draw details for all cells
            for each (cell in cells)
                addCellDetail(reliefLayer.graphics, cell);

//            var filter:BitmapFilter = new BlurFilter(5, 5, BitmapFilterQuality.HIGH);
//            terrainLayer.filters = [filter];
        }

        private function drawCoastlinesLayer():void {
            /**
             * Draw Coastlines
             */

            var coastlineFeatureTypes:Array = [Geography.OCEAN, Geography.LAND, Geography.LAKE];
            var coastlineColors:Object = {
                "land": Biome.colors.saltWater_stroke,
                "lake": Biome.colors.freshWater_stroke
            }
            for each (var featureType:String in coastlineFeatureTypes) {
                for (var key:String in geo.getFeaturesByType(featureType)) {
                    var feature:Object = geo.features[key];
                    for each (var cell:Cell in feature.cells) {
                        for each (var edge:Edge in cell.edges) {
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                if (!edge.d0.features[key] || !edge.d1.features[key]) {
                                    var noisyPoints:Array = edge.noisyPoints;

                                    // Fill
                                    coastlinesLayer.graphics.lineStyle();
                                    for (var i:int = 0; i < noisyPoints.length - 1; i++) {
                                        coastlinesLayer.graphics.beginFill(cell.terrainColor);
                                        coastlinesLayer.graphics.moveTo(noisyPoints[i].x, noisyPoints[i].y);
                                        coastlinesLayer.graphics.lineTo(cell.point.x, cell.point.y);
                                        coastlinesLayer.graphics.lineTo(noisyPoints[i + 1].x, noisyPoints[i + 1].y);
                                        coastlinesLayer.graphics.endFill();
                                    }

                                    // Outline
                                    if (feature.type != Geography.OCEAN) {
                                        coastlinesLayer.graphics.moveTo(noisyPoints[0].x, noisyPoints[0].y);
                                        coastlinesLayer.graphics.lineStyle(1, coastlineColors[featureType]);
                                        for each (var point:Point in noisyPoints)
                                            coastlinesLayer.graphics.lineTo(point.x, point.y);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        private function drawRiversLayer():void {
            /**
             * Draw Rivers
             */

            var seaColor:uint = Biome.colors[Biome.FRESH_WATER];
            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER)) {
                // Create an array of river points
                riversLayer.graphics.moveTo(river.cells[0].point.x, river.cells[0].point.y);
                var i:int = 0;
                for each (var cell:Cell in river.cells) {
                    i++;
                    riversLayer.graphics.lineStyle(1 + ((i / river.cells.length) * river.cells.length) / 5, seaColor);
                    riversLayer.graphics.lineTo(cell.point.x, cell.point.y);
                }
            }
        }

        private function drawForestsLayer():void {
            /**
             * Draw Forests
             */

            // Draw Temperate Forests
            drawForests(Biome.TEMPERATE_FOREST, Biome.colors["temperateForest"], Biome.colors["temperateForest_stroke"], Biome.colors["temperateForest_bottomStroke"]);

            // Draw Boreal Forests (Draw these second because when they overlap, boreal should be on top)
            drawForests(Biome.BOREAL_FOREST, Biome.colors["borealForest"], Biome.colors["borealForest_stroke"], Biome.colors["borealForest_bottomStroke"]);

            function drawForests(type:String, fillColor:uint, outlineColor:uint, bottomOutlineColor:uint):void {
                // Draw forests of a specific type
                for each (var forest:Object in geo.getFeaturesByType(type)) {
                    // Fill
                    forestsLayer.graphics.lineStyle();
                    forestsLayer.graphics.beginFill(fillColor);
                    for each (var cell:Cell in forest.cells) {
                        for (var i:int = 0; i < cell.edges.length; i++) {
                            var edge:Edge = cell.edges[i];
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                forestsLayer.graphics.moveTo(cell.point.x, cell.point.y);
                                forestsLayer.graphics.lineTo(edge.v0.point.x, edge.v0.point.y);
                                if (!edge.d0.features[forest.id]) {
                                    // Draw a curved line
                                    forestsLayer.graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else if (!edge.d1.features[forest.id]) {
                                    // Draw a curved line (opposite direction)
                                    forestsLayer.graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else {
                                    forestsLayer.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                    forestsLayer.graphics.endFill();

                    // Outline
                    for each (cell in forest.cells) {
                        for (i = 0; i < cell.edges.length; i++) {
                            edge = cell.edges[i];
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                forestsLayer.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                if (!edge.d0.features[forest.id]) {
                                    // Draw a curved line
                                    forestsLayer.graphics.lineStyle(1, outlineColor);
                                    forestsLayer.graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else if (!edge.d1.features[forest.id]) {
                                    forestsLayer.graphics.lineStyle(1, bottomOutlineColor);
                                    // Draw a curved line (opposite direction)
                                    forestsLayer.graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                }
            }
        }

        private function drawMountainsLayer():void {
            /**
             * Draw Mountains
             */

            // todo
        }

        private function drawRegionsLayer():void {
            /**
             * Draw Regions
             */

            for each (var region:Object in civ.regions) {
                var regionFill:MovieClip = new MovieClip();
                regionFill.graphics.lineStyle();
                regionFill.graphics.beginFill(0x000000);

                var start:Point = region.borderPoints.shift();
                regionFill.graphics.moveTo(start.x, start.y);
                for each (var p:Point in region.borderPoints)
                    regionFill.graphics.lineTo(p.x, p.y);

                regionFill.graphics.endFill();

                var filter:GlowFilter = new GlowFilter();
                filter.quality = 10;
                filter.blurX = 10;
                filter.blurY = 10;
                filter.strength = .8;
                filter.inner = true;
                filter.knockout = true;
                filter.color = Util.randomColor();

                regionFill.filters = [filter];
                regionFill.cacheAsBitmap = true;

                var regionOutline:MovieClip = new MovieClip();
                regionOutline.graphics.copyFrom(regionFill.graphics);

                filter.strength = 4;
                filter.blurX = 2;
                filter.blurY = 2;

                regionOutline.filters = [filter];
                regionOutline.cacheAsBitmap = true;

                regionsLayer.addChild(regionFill);
                regionsLayer.addChild(regionOutline);
            }
        }

        private function drawRoadsLayer():void {
            /**
             * Draw Roads
             */

            for each (var road:Object in civ.roads) {
                var roadSegments:Array = [[]];
                var i:int = 0;
                for each (var cell:Cell in road.cells) {
                    roadSegments[i].push(cell.point);
                    if (cell.crossroad) {
                        roadSegments.push([cell.point]);
                        i++;
                    }
                }

                roadsLayer.graphics.lineStyle(0x000000);
                for each (var roadSegment:Array in roadSegments)
                    CubicBezier.curveThroughPoints(roadsLayer.graphics, roadSegment, 0x000000);
            }
        }

        private function drawElevationLayer():void {
            /**
             * Draw Elevation
             */

            elevationLayer.graphics.lineStyle();
            for each (var cell:Cell in cells)
                fillCell(elevationLayer.graphics, cell, getColorFromElevation(cell.elevation));
        }

        private function drawTemperatureLayer():void {
            /**
             * Draw Temperature
             */

            temperatureLayer.graphics.lineStyle();
            for each (var cell:Cell in cells) {
                if (cell.elevation > SEA_LEVEL)
                    fillCell(temperatureLayer.graphics, cell, getColorFromTemperature(cell.temperature));
            }
        }

        private function drawOutlinesLayer():void {
            /**
             * Draw outlines
             */
            for each (var edge:Edge in edges) {
                // Draw voronoi diagram
                outlinesLayer.graphics.lineStyle(1, 0x000000, .1);
                if (edge.v0 && edge.v1) {
                    outlinesLayer.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                    outlinesLayer.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                }
            }
        }

        private function getColorFromElevation(elevation:Number):uint {
            if (elevation > 1)
                elevation = 1;

            var colors:Array = [0x4890B1, 0x6DC0A8, 0xC9E99F, 0xE6F5A3, 0xFECC7B];

            var preciseIndex:Number = (colors.length - 1) * elevation;
            var index:int = Math.floor(preciseIndex);

            var color:uint = colors[index];
            if (index < colors.length - 1 && elevation >= SEA_LEVEL)
                color = Util.getColorBetweenColors(colors[index], colors[index + 1], preciseIndex - index);

            return color;
        }

        private function getColorFromTemperature(temperature:Number):uint {
            var colors:Array = [0x0000ff, 0xf49242];

            var preciseIndex:Number = (colors.length - 1) * temperature;
            var index:int = Math.floor(preciseIndex);

            var color:uint = colors[index];
            if (index < colors.length - 1)
                color = Util.getColorBetweenColors(colors[index], colors[index + 1], preciseIndex - index);

            return color;
        }

        public function pickRandomPoints():void {
            // Pick points
            var rand:Rand = new Rand(1);
            points = new Vector.<Point>;
            for (var i:int = 0; i < NUM_POINTS; i++) {
                points.push(new Point(rand.next() * width, rand.next() * height));
            }
        }

        public function build():void {
            // Setup
            var voronoi:Voronoi = new Voronoi(points, null, new Rectangle(0, 0, width, height));
            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            /**
             * Cells
             */

            var cellDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellDictionary[point] = cell;
            }

            for each (cell in cells)
                voronoi.region(cell.point);

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner {
                var corner:Corner;

                if (point == null) return null;
                for (var bucket:int = int(point.x) - 1; bucket <= int(point.x) + 1; bucket++) {
                    for each (corner in _cornerMap[bucket]) {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6) {
                            return corner;
                        }
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket]) _cornerMap[bucket] = [];

                corner = new Corner();
                corner.index = corners.length;
                corners.push(corner);

                corner.point = point;
                corner.border = (point.x == 0 || point.x == width
                        || point.y == 0 || point.y == height);

                _cornerMap[bucket].push(corner);
                return corner;
            }

            /**
             * Edges
             */

            var libEdges:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.Delaunay.Edge in libEdges) {
                var dEdge:LineSegment = libEdge.delaunayLine();
                var vEdge:LineSegment = libEdge.voronoiEdge();

                var edge:Edge = new Edge();
                edge.index = edges.length;
                edges.push(edge);
                edge.midpoint = vEdge.p0 && vEdge.p1 && Point.interpolate(vEdge.p0, vEdge.p1, 0.5);

                edge.v0 = makeCorner(vEdge.p0);
                edge.v1 = makeCorner(vEdge.p1);
                edge.d0 = cellDictionary[dEdge.p0];
                edge.d1 = cellDictionary[dEdge.p1];

                setupEdge(edge);

                if (edge.v0 && edge.v1)
                    edge.noisyPoints = Util.generateNoisyPoints(edge.v0.point, edge.v1.point, 1);
                else
                    edge.noisyPoints = [];
            }

            /**
             * Deal with edges
             */

            borders = new Vector.<Cell>();
            for each (cell in cells) {
                for each (var corner:Corner in cell.corners) {
                    if (corner.border) {
                        borders.push(cell);
                        cell.neighbors = new Vector.<Cell>();
                        break;
                    }
                }
            }
        }

        private function setupEdge(edge:Edge):void {
            if (edge.d0 != null)
                edge.d0.edges.push(edge);

            if (edge.d1 != null)
                edge.d1.edges.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null) {
                addToCellList(edge.d0.neighbors, edge.d1);
                addToCellList(edge.d1.neighbors, edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null) {
                addToCornerList(edge.v0.adjacent, edge.v1);
                addToCornerList(edge.v1.adjacent, edge.v0);
            }

            if (edge.d0 != null) {
                addToCornerList(edge.d0.corners, edge.v0);
                addToCornerList(edge.d0.corners, edge.v1);
            }

            if (edge.d1 != null) {
                addToCornerList(edge.d1.corners, edge.v0);
                addToCornerList(edge.d1.corners, edge.v1);
            }

            if (edge.v0 != null) {
                addToCellList(edge.v0.touches, edge.d0);
                addToCellList(edge.v0.touches, edge.d1);
            }

            if (edge.v1 != null) {
                addToCellList(edge.v1.touches, edge.d0);
                addToCellList(edge.v1.touches, edge.d1);
            }

            // Calculate Angles
            if (edge.d0 && edge.d1)
                edge.delaunayAngle = Math.atan2(edge.d1.point.y - edge.d0.point.y, edge.d1.point.x - edge.d0.point.x);

            if (edge.v0 && edge.v1)
                edge.voronoiAngle = Math.atan2(edge.v1.point.y - edge.v0.point.y, edge.v1.point.x - edge.v0.point.x);

            function addToCornerList(v:Vector.<Corner>, x:Corner):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>, x:Cell):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }
        }

        private function humanReadablePoint(p:Point):String {
            return "(" + p.x.toFixed(1) + ", " + p.y.toFixed(1) + ")";
        }

        private function reset():void {
            // Reset Geography
            geo.reset();
            civ.reset();
            names.reset();

            // Reset cells
            for each (var cell:Cell in cells)
                cell.reset();

            cells.sort(Sort.sortByIndex);

            unuseCells();
        }

        private function onClick(event:MouseEvent):void {
            var cell:Cell = getCellClosestToPoint(mouse);
            trace(humanReadableCell(cell));
        }

        private function humanReadableCell(cell:Cell):String {
            var str:String = "#" + cell.index;
            if (cell.town)
                str += "\n" + cell.town.name;
            for each (var feature:Object in cell.features) {
                str += "\n > " + feature.type + " (" + feature.cells.length + ")";
                if (feature.ecosystem) {
                    str += " - " + feature.ecosystem.size;
                    if (feature.ecosystem.trees.length > 0)
                        str += "\n   > " + feature.ecosystem.trees;
                    if (feature.ecosystem.plants.length > 0)
                        str += "\n   > " + feature.ecosystem.plants;
                    if (feature.ecosystem.smallAnimals.length > 0)
                        str += "\n   > " + feature.ecosystem.smallAnimals;
                    if (feature.ecosystem.bigAnimals.length > 0)
                        str += "\n   > " + feature.ecosystem.bigAnimals;
                }
            }

            //var region:Object = civ.regions[cell.region];

            return str;
        }

        public function get mouse():Point {
            // Return a point referring to the current mouse position
            return new Point(mouseX, mouseY);
        }

        public function staticModeOn():void {
            // Show screenshot
            staticMode.visible = true;
            hide();
        }

        public function staticModeOff():void {
            // Hide screenshot
            staticMode.visible = false;
            show();

            // Static Mode
            var source:BitmapData = new BitmapData(this.width, this.height);
            source.draw(this);
            staticMode.bitmapData = source;
            staticMode.smoothing = true;
        }

        public function hide():void {
            for each (var layer:MovieClip in layers)
                layer.visible = false;
        }

        public function show():void {
            oceanLayer.visible = drawOcean;
            terrainLayer.visible = drawTerrain;
            reliefLayer.visible = drawTerrain;
            coastlinesLayer.visible = drawCoastlines;
            riversLayer.visible = drawRivers;
            forestsLayer.visible = drawForests;
            mountainsLayer.visible = drawMountains;
            roadsLayer.visible = drawRoads;
            regionsLayer.visible = drawRegions;
            elevationLayer.visible = drawElevation;
            temperatureLayer.visible = drawTemperature;
            outlinesLayer.visible = drawOutlines;
        }
    }
}