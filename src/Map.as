package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

    import flash.display.Shape;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;

    import geography.Biome;
    import geography.Geography;

    import graph.Center;
    import graph.Corner;
    import graph.Edge;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Map extends UIComponent {
        public static var NUM_POINTS:int = 24000;
        public static var SEA_LEVEL:Number = .2;
        public static var MOUNTAIN_ELEVATION:Number = .9;
        public static var MOUNTAIN_ELEVATION_ADJACENT:Number = .85;

        public var seed:int;

        // Map Storage
        public var points:Vector.<Point>;
        public var centers:Vector.<Center>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;
        public var borders:Vector.<Center>;

        // Managers
        private var featureManager:Geography;

        // Generation
        private var outlines:Shape;
        private var rand:Rand;

        // Draw Toggles
        public var showOutlines:Boolean = false;
        public var showTerrain:Boolean = false;
        public var showRivers:Boolean = true;
        public var showBiomes:Boolean = true;
        public var showPrecipitation:Boolean = false;
        public var showTemperature:Boolean = false;
        public var showForests:Boolean = true;
        public var showMountains:Boolean = true;

        // Miscellanious
        public static var MAP_PROGRESS:String = "mapProgress";

        public function Map() {
            // Initialize Singletons
            featureManager = Geography.getInstance();

            // Seeded random generator
            rand = new Rand(1);

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            progress(0, "Preparing points");

            setTimeout(tryToLoadPoints, 500);

            addEventListener(MouseEvent.CLICK, onClick);
            addEventListener(MouseEvent.RIGHT_CLICK, onRightClick);
        }

        override protected function createChildren():void {
            super.createChildren();

            outlines = new Shape();
            addChild(outlines);
        }

        private function tryToLoadPoints():void {
            // Determine if points file exists
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
            trace("Points generated!");

            if (Util.isAir()) {
                AirOnlyUtil.savePointsToFile(points);
            }
        }

        private function progress(percent:Number, message:String):void {
            this.dispatchEvent(new PayloadEvent(MAP_PROGRESS, {percent: percent, message: message}, true));
        }

        public function start(seed:Number = 1):void {
            // Set map seed - the whole map uses this seed for any random decision making
            rand = new Rand(seed);
            this.seed = seed;

            var tasks:Array = [{f: generateHeightMap, m: "Generating height map"},
                {f: resolveDepressions, m: "Smoothing"},
                {f: determineOceanLandsAndLakes, m: "Determining coastlines"},
                {f: calculateTemperature, m: "Calculating temperature"},
                {f: calculateMoisture, m: "Calculating moisture"},
                {f: calculateRivers, m: "Calculating rivers"},
                {f: determineBiomes, m: "Determining biomes"},
                {f: draw, m: "Drawing"}];

            progress(0, tasks[0].m);
            setTimeout(performTask, 200, 0);

            function performTask(i:int):void {
                tasks[i].f();

                i++;

                if (i > tasks.length - 1) {
                    progress(1, "");
                } else {
                    progress(i / tasks.length, tasks[i].m);
                    setTimeout(performTask, 200, i);
                }
            }

//            for each (var feature:Object in featureManager.features) {
//                if (Geography.type != Geography.RIVER && Geography.type != Geography.OCEAN && Geography.type != Geography.LAND && Geography.type != Geography.LAKE)
//                    trace(Geography.type, Geography.centers.length);
//            }
        }

        private function determineBiomes():void {
            for each (var land:Object in featureManager.getFeaturesByType(Geography.LAND)) {
                var landCenters:Vector.<Center> = land.centers.concat();
                var queue:Array = [];
                while (landCenters.length > 0) {
                    var start:Center = landCenters[0];
                    start.used = true;

                    // Pick a starting biome
                    var currentBiome:String = Biome.determineBiome(start);
                    var currentFeature:String = featureManager.registerFeature(currentBiome);
                    featureManager.addCenterToFeature(start, currentFeature);
                    start.biome = currentFeature;
                    start.biomeType = currentBiome;

                    // Fill touching centers
                    queue.push(start);
                    var center:Center;
                    while (queue.length > 0) {
                        center = queue[0];
                        queue.shift();
                        for each (var neighbor:Center in center.neighbors) {
                            var d:Boolean = Biome.determineBiome(neighbor) == currentBiome;
                            if (!neighbor.used && land.centers.indexOf(neighbor) >= 0 && d) {
                                featureManager.addCenterToFeature(neighbor, currentFeature);
                                neighbor.biome = currentFeature;
                                neighbor.biomeType = currentBiome;
                                queue.push(neighbor);
                                neighbor.used = true;
                            }
                        }
                    }

                    landCenters = new Vector.<Center>();
                    for each (center in land.centers)
                        if (!center.used)
                            landCenters.push(center);
                }
            }

            unuseCenters();
        }


        private function calculateRivers():void {
            // Sort list centers neighbors by their elevation from lowest to highest
            for each (var center:Center in centers) {
                if (center.neighbors.length > 0) {
                    center.neighbors.sort(sortByLowestElevation);
                }
            }

            // Create rivers
            for each (var land:Object in featureManager.getFeaturesByType(Geography.LAND)) {
                for each (center in land.centers) {
                    center.flux = center.moisture;
                }

                land.centers.sort(sortByHighestElevation);
                for each (center in land.centers) {
                    pour(center, center.neighbors[0]);
                }
            }

            function pour(c:Center, t:Center):void {
                t.flux += c.flux;
                if (c.flux > 10) {
                    var river:String;
                    if (c.hasFeatureType(Geography.RIVER)) {
                        // Extend river
                        var rivers:Object = c.getFeaturesByType(Geography.RIVER);
                        for (var v:String in rivers) {
                            // Pick the longest river to continue
                            if (!river || rivers[v].centers.length > rivers[river].centers.length) {
                                river = v;
                            }
                        }
                        featureManager.addCenterToFeature(t, river);
                    } else {
                        // Start new river
                        river = featureManager.registerFeature(Geography.RIVER);
                        featureManager.addCenterToFeature(c, river);
                        featureManager.addCenterToFeature(t, river);
                    }
                }
            }

            unuseCenters();
        }

        private function sortByLowestElevation(n1:Center, n2:Center):Number {
            if (n1.elevation > n2.elevation)
                return 1;
            else if (n1.elevation < n2.elevation)
                return -1;
            else
                return 0;
        }

        private function sortByHighestElevation(n1:Center, n2:Center):Number {
            if (n1.elevation < n2.elevation)
                return 1;
            else if (n1.elevation > n2.elevation)
                return -1;
            else
                return 0;
        }

        private function resolveDepressions():void {
            var depressions:int;
            do {
                depressions = 0;
                for each (var center:Center in centers) {
                    if (center.neighbors.length > 0) {
                        var d:Boolean = center.elevation >= SEA_LEVEL;
                        for each (var neighbor:Center in center.neighbors) {
                            if (neighbor.elevation < center.elevation)
                                d = false;
                        }
                    }
                    if (d) {
                        depressions++;
                        center.elevation += .1;
                    }
                }
            } while (depressions > 0);
        }

        private function calculateMoisture():void {
            for each (var center:Center in centers) {
                var m:Number = 0;

                for each (var neighbor:Center in center.neighbors)
                    m += neighbor.elevation;
                m /= center.neighbors.length;

                center.moisture = m;
                center.precipitation = Util.round(200 + (center.moisture * 1800), 2);
            }
        }

        private function calculateTemperature():void {
            for each (var center:Center in centers) {
                // Mapping 0 to 90 realLatitude for this section of the world
                center.latitude = 1 - (center.point.y / height);
                center.realLatitude = Util.round(center.latitude * 90, 2);
                var temperature:Number = 1 - center.latitude;

                // Consider elevation in the temperature (higher places are colder)
                center.temperature = temperature - (center.elevation * .3);
                if (center.temperature < 0)
                    center.temperature = 0;
                if (center.temperature > 1)
                    center.temperature = 1;

                center.realTemperature = Util.round(-10 + (center.temperature * 40), 2);
            }
        }

        private function determineOceanLandsAndLakes():void {
            var queue:Array = [];

            // Start with a site that is at 0 elevation and is in the upper left
            // Don't pick a border site because they're fucky
            for each (var start:Center in centers) {
                if (start.elevation == 0 && start.neighbors.length > 0)
                    break;
            }

            var ocean:String = featureManager.registerFeature(Geography.OCEAN);
            featureManager.addCenterToFeature(start, ocean);
            start.used = true;
            queue.push(start);

            // Define Ocean
            var biome:String = featureManager.registerFeature(Biome.SALT_WATER);
            while (queue.length > 0) {
                var center:Center = queue.shift();
                for each (var neighbor:Center in center.neighbors) {
                    if (!neighbor.used && neighbor.elevation < SEA_LEVEL) {
                        featureManager.addCenterToFeature(neighbor, ocean);
                        featureManager.addCenterToFeature(neighbor, biome);
                        queue.push(neighbor);
                        neighbor.used = true;
                    }
                }
            }

            // Override list borders to be part of the Ocean
            for each (center in borders) {
                featureManager.addCenterToFeature(center, ocean);
                featureManager.addCenterToFeature(center, biome);
            }


            // Define Land and Lakes
            var nonOceans:Vector.<Center> = new Vector.<Center>();
            for each (center in centers)
                if (Util.getLengthOfObject(center.features) == 0)
                    nonOceans.push(center);

            var currentFeature:String;
            while (nonOceans.length > 0) {
                start = nonOceans[0];

                var lower:Number;
                var upper:Number;

                // If the elevation of the center is higher than sea level, define it as Land otherwise define it as a Lake
                if (start.elevation >= SEA_LEVEL) {
                    // Define it as land
                    currentFeature = featureManager.registerFeature(Geography.LAND);
                    biome = null;

                    lower = SEA_LEVEL;
                    upper = 100;
                } else {
                    // Define it as a lake
                    currentFeature = featureManager.registerFeature(Geography.LAKE);
                    biome = featureManager.registerFeature(Biome.FRESH_WATER);

                    lower = -100;
                    upper = SEA_LEVEL;
                }

                featureManager.addCenterToFeature(start, currentFeature);
                if (biome)
                    featureManager.addCenterToFeature(start, biome);

                start.used = true;

                // Fill touching Land or Lake centers
                queue.push(start);
                while (queue.length > 0) {
                    center = queue[0];
                    queue.shift();
                    for each (neighbor in center.neighbors) {
                        if (!neighbor.used && neighbor.elevation >= lower && neighbor.elevation < upper) {
                            featureManager.addCenterToFeature(neighbor, currentFeature);
                            if (biome)
                                featureManager.addCenterToFeature(neighbor, biome);

                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }

                nonOceans = new Vector.<Center>();
                for each (center in centers)
                    if (Util.getLengthOfObject(center.features) == 0)
                        nonOceans.push(center);
            }

            unuseCenters();
        }

        private function generateHeightMap():void {
            // Generate a height map
            reset();

            var center:Center;
            var w:Number = width / 2;
            var h:Number = height / 2;

            // Add mountain
            placeMountain(centerFromDistribution(0), .8, .95, .2);

            // Add hills
            for (var i:int = 0; i < 30; i++)
                placeHill(centerFromDistribution(.25), rand.between(.5, .8), rand.between(.95, .99), rand.between(.1, .2));

            // Add troughs

            // Add pits
            for (i = 0; i < 15; i++)
                placePit(centerFromDistribution(.35), rand.between(.2, .7), rand.between(.8, .95), rand.between(0, .2));

            // Subtract .05 from land cells
            addToLandCells(-.05);

            // Multiply land cells by .9
            multiplyLandCellsBy(.9);

            function centerFromDistribution(distribution:Number):Center {
                // 0 is map center
                // 1 is map border
                var dw:Number = distribution * width;
                var dh:Number = distribution * height;
                var px:Number = w + ((rand.next() * 2 * dw) - dw);
                var py:Number = h + ((rand.next() * 2 * dh) - dh);

                return getCenterClosestToPoint(new Point(px, py));
            }

            function addToLandCells(value:Number):void {
                for each (center in centers)
                    if (center.elevation > SEA_LEVEL)
                        center.elevation += value;
            }

            function multiplyLandCellsBy(value:Number):void {
                for each (center in centers)
                    if (center.elevation > SEA_LEVEL)
                        center.elevation *= value;
            }
        }

        private function placeMountain(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            // Can only be placed once, at the beginning
            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;
            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation = (queue[i] as Center).elevation * radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
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

            unuseCenters();
        }

        private function placeHill(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;

            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation *= radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
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

            unuseCenters();
        }

        private function placePit(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            var queue:Array = [];
            elevation *= -1;
            start.elevation += elevation;
            if (start.elevation < 0)
                start.elevation = 0;

            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation < SEA_LEVEL - .01; i++) {
                elevation *= radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
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

            unuseCenters();
        }

        private function unuseCenters():void {
            for each (var center:Center in centers) {
                center.used = false;
            }
        }

        private function relaxPoints():void {
            points = new Vector.<Point>();
            for each (var center:Center in centers) {
                var centroid:Point = new Point();
                for each (var corner:Corner in center.corners) {
                    centroid.x += corner.point.x;
                    centroid.y += corner.point.y;
                }

                centroid.x /= center.corners.length;
                centroid.y /= center.corners.length;

                points.push(Point.interpolate(center.point, centroid, 0.5));
            }

            // Rebuild graph
            build();
        }

        public function getCenterClosestToPoint(p:Point):Center {
            var shortestDistance:Number = Number.POSITIVE_INFINITY;
            var closestCenter:Center;
            var distance:Number;

            for each (var center:Center in centers) {
                distance = (center.point.x - p.x) * (center.point.x - p.x) + (center.point.y - p.y) * (center.point.y - p.y);
                if (distance < shortestDistance) {
                    closestCenter = center;
                    shortestDistance = distance;
                }
            }

            return closestCenter;
        }

        public function draw():void {
            /**
             * Main Draw Call
             */

            // Clear
            graphics.clear();
            outlines.graphics.clear();

            graphics.beginFill(Biome.colors[Biome.SALT_WATER]);
            graphics.drawRect(0, 0, width, height);

            var center:Center;
            var edge:Edge;

            if (showBiomes) {
                // Draw Biomes
                graphics.lineStyle();
                for each (var biomeName:String in Biome.list) {
                    graphics.beginFill(Biome.colors[biomeName]);
                    for each (var biome:Object in featureManager.getFeaturesByType(biomeName)) {
                        for each (center in biome.centers) {
                            // Loop through edges
                            for each (edge in center.borders) {
                                if (edge.v0 && edge.v1) {
                                    graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                    graphics.lineTo(center.point.x, center.point.y);
                                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                } else {
                                }
                            }
                        }
                    }
                    graphics.endFill();
                }
            }

            drawCoastline();

            if (showRivers) {
                // Draw rivers
                var seaColor:uint = Biome.colors[Biome.FRESH_WATER];
                for each (var river:Object in featureManager.getFeaturesByType(Geography.RIVER)) {
                    // Create an array of points
                    graphics.moveTo(river.centers[0].point.x, river.centers[0].point.y);
                    var i:int = 0;
                    for each (center in river.centers) {
                        i++;
                        graphics.lineStyle(1 + ((i / river.centers.length) * river.centers.length) / 5, seaColor);
                        graphics.lineTo(center.point.x, center.point.y);
                    }
                }
            }

            if (showForests) {
                // Draw forests
                drawForests(Biome.TEMPERATE_FOREST, Biome.colors["temperateForest"], Biome.colors["temperateForest_stroke"], Biome.colors["temperateForest_bottomStroke"]);
                drawForests(Biome.BOREAL_FOREST, Biome.colors["borealForest"], Biome.colors["borealForest_stroke"], Biome.colors["borealForest_bottomStroke"]);
            }

            if (showMountains) {
                // Draw mountains
                graphics.lineStyle(1, 0xff0000, .2);
                for each (var mountain:Object in featureManager.getFeaturesByType(Biome.MOUNTAIN)) {
                    var mountainBase:Array = [];
                    var mountainBody:Array = [];
                    for each (center in mountain.centers) {
                        var isBase:Boolean = false;
                        for each (var neighbor:Center in center.neighbors) {
                            if (!neighbor.hasFeatureType(Biome.MOUNTAIN)) {
                                isBase = true;
                                break;
                            }
                        }
                        if (!isBase)
                            mountainBody.push(center);
                        else
                            mountainBase.push(center);
                    }

                    mountainBody = mountainBody.sortOn("elevation", Array.DESCENDING);

                    graphics.lineStyle(1, 0x000000);
                    for each (center in mountainBody) {
                        var d:Number = (center.elevation - MOUNTAIN_ELEVATION_ADJACENT) / (1 - MOUNTAIN_ELEVATION_ADJACENT) * 20;
                        for each (neighbor in center.neighbors) {
                            var f:Number = (neighbor.elevation - MOUNTAIN_ELEVATION_ADJACENT) / (1 - MOUNTAIN_ELEVATION_ADJACENT) * 20;
                            graphics.moveTo(center.point.x, center.point.y - (d));
                            if (Math.abs(d - f) > 1)
                                graphics.lineTo(neighbor.point.x, center.point.y - (f));
                        }
                    }
                }
            }

            if (showBiomes) {
                // Draw details on biomes
                for each (center in centers) {
                    addCenterDetail(center);
                }
            }

            if (showTemperature) {
                // Draw temperature
                graphics.lineStyle();
                for each (center in centers) {
                    if (center.elevation > SEA_LEVEL) {
                        graphics.beginFill(getColorFromTemperature(center.temperature), .6);
                        for each (edge in center.borders) {
                            if (edge.v0 && edge.v1) {
                                graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                graphics.lineTo(center.point.x, center.point.y);
                                graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            } else {
                            }
                        }
                        graphics.endFill();
                    }
                }
            }

            if (showTerrain) {
                // Draw terrain
                graphics.lineStyle();
                for each (var center:Center in centers) {
                    graphics.beginFill(getColorFromElevation(center.elevation), 1);

                    for each (var edge:Edge in center.borders) {
                        if (edge.v0 && edge.v1) {
                            graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                            graphics.lineTo(center.point.x, center.point.y);
                            graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                        } else {
                        }
                    }
                }
                graphics.endFill();
            }

            if (showPrecipitation) {
                // Draw flux
                graphics.lineStyle(1, 0x0000ff, 0.3);
                for each (center in centers) {
                    graphics.drawCircle(center.point.x, center.point.y, center.moisture * 5);
                }
            }

            if (showOutlines) {
                // Draw outlines
                for each (edge in edges) {
                    // Draw voronoi diagram
                    outlines.graphics.lineStyle(1, 0x000000, .2);
                    if (edge.v0 && edge.v1) {
                        outlines.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                        outlines.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                    } else {
                    }
                }
            }
        }

        private function drawForests(type:String, fillColor:uint, outlineColor:uint, bottomOutlineColor:uint):void {
            // Draw forests
            for each (var forest:Object in featureManager.getFeaturesByType(type)) {
                // Fill
                graphics.lineStyle();
                graphics.beginFill(fillColor);
                for each (var center:Center in forest.centers) {
                    for (var i:int = 0; i < center.borders.length; i++) {
                        var edge:Edge = center.borders[i];
                        if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                            graphics.moveTo(center.point.x, center.point.y);
                            graphics.lineTo(edge.v0.point.x, edge.v0.point.y);
                            if (!edge.d0.features[forest.id]) {
                                // Draw a curved line
                                graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                            } else if (!edge.d1.features[forest.id]) {
                                // Draw a curved line (opposite direction)
                                graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                            } else {
                                graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            }
                        }
                    }
                }
                graphics.endFill();

                // Outline
                for each (center in forest.centers) {
                    for (i = 0; i < center.borders.length; i++) {
                        edge = center.borders[i];
                        if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                            graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                            if (!edge.d0.features[forest.id]) {
                                // Draw a curved line
                                graphics.lineStyle(1, outlineColor);
                                graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                            } else if (!edge.d1.features[forest.id]) {
                                graphics.lineStyle(1, bottomOutlineColor);
                                // Draw a curved line (opposite direction)
                                graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                            }
                        }
                    }
                }
            }
        }

        private function addCenterDetail(center:Center):void {
            var iconDensity:Number = 0;
            var c:Point = new Point(center.point.x + rand.between(-4, 4), center.point.y + rand.between(-4, 4));
            var d:Number;

            if (center.hasFeatureType(Biome.TEMPERATE_FOREST)) {
                iconDensity = .4;

                if (rand.next() > iconDensity)
                    return;

                if (bordersForeignType(Biome.TEMPERATE_FOREST))
                    return;

                graphics.lineStyle(rand.between(1, 1.5), Biome.colors["temperateForest_stroke"], rand.between(.6, 1));
                graphics.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                graphics.curveTo(c.x, c.y - rand.between(1, 5), c.x + d, c.y);
            }
            if (center.hasFeatureType(Biome.BOREAL_FOREST)) {
                iconDensity = .8;

                if (rand.next() > iconDensity)
                    return;

                graphics.lineStyle(rand.between(.5, 1.5), Biome.colors["borealForest_stroke"], rand.between(.6, 1));
                graphics.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                graphics.lineTo(c.x, c.y - rand.between(1, 3));
                graphics.lineTo(c.x + d, c.y);
            }

            function bordersForeignType(type:String):Boolean {
                // Check that the center isn't bordering any foreign biome types
                for each (var neighbor:Center in center.neighbors)
                    if (!neighbor.hasFeatureType(type))
                        return true;
                return false;
            }

            if (rand.next() < iconDensity)
                addCenterDetail(center);
        }

        private function drawCoastline():void {
            drawFeatureOutlines(Geography.LAND);
            drawFeatureOutlines(Geography.LAKE);
        }

        private function drawFeatureOutlines(featureType:String):void {
            for (var key:String in featureManager.getFeaturesByType(featureType)) {
                var feature:Object = featureManager.features[key];
                graphics.lineStyle(1, Biome.colors.saltWater_stroke);
                if (feature.type != Geography.OCEAN) {
                    for each (var center:Center in feature.centers) {
                        for each (var edge:Edge in center.borders) {
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                if (!edge.d0.features[key]) {
                                    // Draw a line
                                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                } else if (!edge.d1.features[key]) {
                                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
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
            points = new Vector.<Point>;
            for (var i:int = 0; i < NUM_POINTS; i++) {
                points.push(new Point(rand.next() * width, rand.next() * height));
            }
        }

        public function build():void {
            // Setup
            var voronoi:Voronoi = new Voronoi(points, null, new Rectangle(0, 0, width, height));
            centers = new Vector.<Center>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            /**
             * Centers
             */

            var centerDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var center:Center = new Center();
                center.index = centers.length;
                center.point = point;
                centers.push(center);
                centerDictionary[point] = center;
            }

            for each (center in centers) {
                voronoi.region(center.point);
            }

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
                edge.d0 = centerDictionary[dEdge.p0];
                edge.d1 = centerDictionary[dEdge.p1];

                setupEdge(edge);
            }

            /**
             * Deal with borders
             */

            borders = new Vector.<Center>();
            for each (center in centers) {
                for each (var corner:Corner in center.corners) {
                    if (corner.border) {
                        borders.push(center);
                        center.neighbors = new Vector.<Center>();
                        break;
                    }
                }
            }
        }

        private function setupEdge(edge:Edge):void {
            if (edge.d0 != null)
                edge.d0.borders.push(edge);

            if (edge.d1 != null)
                edge.d1.borders.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null) {
                addToCenterList(edge.d0.neighbors, edge.d1);
                addToCenterList(edge.d1.neighbors, edge.d0);
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
                addToCenterList(edge.v0.touches, edge.d0);
                addToCenterList(edge.v0.touches, edge.d1);
            }

            if (edge.v1 != null) {
                addToCenterList(edge.v1.touches, edge.d0);
                addToCenterList(edge.v1.touches, edge.d1);
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

            function addToCenterList(v:Vector.<Center>, x:Center):void {
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
            featureManager.reset();

            // Reset centers
            for each (var center:Center in centers)
                center.reset();

            unuseCenters();
        }

        private function onClick(event:MouseEvent):void {
            var center:Center = getCenterClosestToPoint(mouse);
            trace(humanReadableCenter(center));
        }

        private function humanReadableCenter(center:Center):String {
            var str:String = "#" + center.index;
            str += "\n  elevation: " + center.realElevation + " m";
            str += "\n  elevation: " + center.elevation;
            str += "\n  latitude: " + center.realLatitude + " °N";
            str += "\n  temperature: " + center.realTemperature + " °C";
            str += "\n  precipitation: " + center.precipitation + " mm/year";
            for each (var feature:Object in center.features)
                str += "\n > " + feature.type + " (" + feature.centers.length + ")";

            return str;
        }

        private function onRightClick(event:MouseEvent):void {
        }

        public function get mouse():Point {
            // Return a point referring to the current mouse position
            return new Point(mouseX, mouseY);
        }
    }
}
