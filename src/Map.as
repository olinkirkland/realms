package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

    import flash.display.Shape;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.ui.Keyboard;
    import flash.utils.Dictionary;

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

        // Map Storage
        public var points:Vector.<Point>;
        public var centers:Vector.<Center>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;
        public var borders:Vector.<Center>;

        // Managers
        private var featureManager:Geography;

        // Generation
        private var pointsFile:File;
        private var outlines:Shape;

        // Miscellaneous
        private var showOutlines:Boolean = false;
        private var showTerrain:Boolean = true;
        private var showRivers:Boolean = true;
        private var showBiomes:Boolean = true;
        private var showPrecipitation:Boolean = false;
        private var showTemperature:Boolean = false;

        public function Map() {
            // Initialize Singletons
            featureManager = Geography.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            tryToLoadPoints();
            start();

            addEventListener(MouseEvent.CLICK, onClick);

            addEventListener(MouseEvent.RIGHT_CLICK, onRightClick);
            systemManager.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        override protected function createChildren():void {
            super.createChildren();

            outlines = new Shape();
            addChild(outlines);
        }

        private function tryToLoadPoints():void {
            // Determine if points file exists
            var pointsData:Object;
            pointsFile = File.applicationStorageDirectory.resolvePath("points.json");
            if (pointsFile.exists) {
                // Load the points file
                trace("Points file found; Loading points from file")
                var stream:FileStream = new FileStream();
                stream.open(pointsFile, FileMode.READ);
                pointsData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
                stream.close();

                points = new Vector.<Point>();
                for each (var pointData:Object in pointsData) {
                    points.push(new Point(pointData.x, pointData.y));
                }
                if (points.length != NUM_POINTS) {
                    trace("Points file incompatible or corrupted, deleting points file");
                    pointsFile.deleteFile();
                    tryToLoadPoints();
                }
                trace("Building graph ...");
                build();
            } else {
                generatePoints();
            }
        }

        private function generatePoints():void {
            // Generate points and save them
            trace("Points file not found; Generating new points ...");
            pickRandomPoints();
            trace("Building 0/4");
            build();
            trace("Building 1/4");
            relaxPoints();
            trace("Building 2/4");
            relaxPoints();
            trace("Building 3/4");
            relaxPoints();
            trace("Building 4/4");
            relaxPoints();
            trace("Points generated!");

            var stream:FileStream = new FileStream();
            stream.open(pointsFile, FileMode.WRITE);
            stream.writeUTFBytes(JSON.stringify(points));
            stream.close();
            trace("Points saved to " + pointsFile.url);
        }

        private function start(seed:Number = 1):void {
            var time:Number = new Date().time;

            generateHeightMap(seed);
            resolveDepressions();
            defineOceanLandsAndLakes();
            calculateTemperature();
            calculateMoisture();
            calculateRivers();
            determinePrimaryBiomes();
            determineSecondaryBiomes();

            draw();

//            for each (var feature:Object in featureManager.features) {
//                if (Geography.type != Geography.RIVER && Geography.type != Geography.OCEAN && Geography.type != Geography.LAND && Geography.type != Geography.LAKE)
//                    trace(Geography.type, Geography.centers.length);
//            }

            var timeTaken:Number = ((new Date().time - time) / 1000);
            trace("Generation and drawing finished in " + timeTaken.toFixed(3) + " s");
        }

        private function determineSecondaryBiomes():void {
            trace("Determining secondary land biomes");
            for each (var land:Object in featureManager.getFeaturesByType(Geography.LAND)) {
                var landCenters:Vector.<Center> = land.centers.concat();
                var queue:Array = [];
                while (landCenters.length > 0) {
                    var start:Center = landCenters[0];
                    start.used = true;

                    // Pick a starting biome
                    var currentBiome:String = Biome.determineSecondaryBiome(start);
                    if (currentBiome) {
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
                                var d:Boolean = Biome.determineSecondaryBiome(neighbor) == currentBiome;
                                if (!neighbor.used && land.centers.indexOf(neighbor) >= 0 && d) {
                                    featureManager.addCenterToFeature(neighbor, currentFeature);
                                    neighbor.biome = currentFeature;
                                    neighbor.biomeType = currentBiome;
                                    queue.push(neighbor);
                                    neighbor.used = true;
                                }
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

        private function determinePrimaryBiomes():void {
            trace("Determining primary land biomes");
            for each (var land:Object in featureManager.getFeaturesByType(Geography.LAND)) {
                var landCenters:Vector.<Center> = land.centers.concat();
                var queue:Array = [];
                while (landCenters.length > 0) {
                    var start:Center = landCenters[0];
                    start.used = true;

                    // Pick a starting biome
                    var currentBiome:String = Biome.determinePrimaryBiome(start);
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
                            var d:Boolean = Biome.determinePrimaryBiome(neighbor) == currentBiome;
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
            trace("Calculating rivers");
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
            trace("Resolving depressions");
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

        private function defineOceanLandsAndLakes():void {
            trace("Defining ocean, lands, and lakes");
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

        private function generateHeightMap(seed:Number = 1):void {
            // Generate a height map
            trace("Generating @seed: " + seed);
            reset();

            var center:Center;
            var r:Rand = new Rand(seed);
            var w:Number = width / 2;
            var h:Number = height / 2;

            // Add mountain
            placeMountain(centerFromDistribution(0), .8, .95, .2, 1);

            // Add hills
            for (var i:int = 0; i < 30; i++)
                placeHill(centerFromDistribution(.25), r.between(.5, .8), r.between(.95, .99), r.between(.1, .2), r.next());

            // Add troughs

            // Add pits
            for (i = 0; i < 15; i++)
                placePit(centerFromDistribution(.35), r.between(.2, .7), r.between(.8, .95), r.between(0, .2), r.next());

            // Subtract .05 from land cells
            addToLandCells(-.05);

            // Multiply land cells by .9
            multiplyLandCellsBy(.9);

            function centerFromDistribution(distribution:Number):Center {
                // 0 is map center
                // 1 is map border
                var dw:Number = distribution * width;
                var dh:Number = distribution * height;
                var px:Number = w + ((r.next() * 2 * dw) - dw);
                var py:Number = h + ((r.next() * 2 * dh) - dh);

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

        private function placeMountain(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0, seed:Number = 1):void {
            // Can only be placed once, at the beginning
            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;
            start.used = true;
            queue.push(start);
            var r:Rand = new Rand(seed);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation = (queue[i] as Center).elevation * radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = (r.next() * sharpness) + 1.1 - sharpness;
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

        private function placeHill(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0, seed:Number = 1):void {
            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;

            start.used = true;
            queue.push(start);
            var r:Rand = new Rand(seed);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation *= radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = sharpness > 0 ? r.next() * sharpness + 1.1 - sharpness : 1;
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

        private function placePit(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0, seed:Number = 1):void {
            var queue:Array = [];
            elevation *= -1;
            start.elevation += elevation;
            if (start.elevation < 0)
                start.elevation = 0;

            start.used = true;
            queue.push(start);
            var r:Rand = new Rand(seed);

            for (var i:int = 0; i < queue.length && elevation < SEA_LEVEL - .01; i++) {
                elevation *= radius;
                for each (var neighbor:Center in (queue[i] as Center).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = sharpness > 0 ? r.next() * sharpness + 1.1 - sharpness : 1;
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

        private function draw():void {
            /**
             * Main Draw Call
             */

            // Clear
            graphics.clear();
            outlines.graphics.clear();

            if (showTerrain) {
                // Draw terrain
                graphics.beginFill(getColorFromElevation(0));
                graphics.drawRect(0, 0, width, height);

                for each (var center:Center in centers) {
                    graphics.beginFill(getColorFromElevation(center.elevation));

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

            if (showBiomes) {
                // Draw Biomes
                graphics.lineStyle();
                for each (var biomeName:String in Biome.list) {
                    graphics.beginFill(Biome.colors[biomeName]);
                    for each (var biome:Object in featureManager.getFeaturesByType(biomeName)) {
                        for each (center in biome.centers) {
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

            if (showTemperature) {
                // Draw temperature
                graphics.lineStyle();
                for each (center in centers) {
                    if (center.elevation > SEA_LEVEL) {
                        graphics.beginFill(getColorFromTemperature(center.temperature));
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

            if (showRivers) {
                // Draw rivers
                var seaColor:uint = getColorFromElevation(0);
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

        private function drawCoastline():void {
            drawFeatureOutlines(Geography.LAND);
            drawFeatureOutlines(Geography.LAKE);
        }

        private function drawFeatureOutlines(featureType:String):void {
            for (var key:String in featureManager.getFeaturesByType(featureType)) {
                var feature:Object = featureManager.features[key];
                graphics.lineStyle(1, feature.color);
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

        public function pickRandomPoints(seed:Number = 1):void {
            // Pick points
            points = new Vector.<Point>;
            var r:Rand = new Rand(seed);
            for (var i:int = 0; i < NUM_POINTS; i++) {
                points.push(new Point(r.next() * width, r.next() * height));
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
            var p:int = -1;
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

        public function onKeyDown(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.Q:
                    // Toggle outlines
                    showOutlines = !showOutlines;
                    draw();
                    break;
                case Keyboard.W:
                    showRivers = !showRivers;
                    draw();
                    break;
                case Keyboard.E:
                    // Toggle Temperature
                    showTemperature = !showTemperature;
                    draw();
                    break;
                case Keyboard.R:
                    // Generate with a new seed
                    start(int(Math.random() * 9999));
                    break;
                case Keyboard.T:
                    // Toggle terrain
                    showTerrain = !showTerrain;
                    draw();
                    break;
                case Keyboard.P:
                    // Toggle flux
                    showPrecipitation = !showPrecipitation;
                    draw();
                    break;
                case Keyboard.B:
                    // Toggle biomes
                    showBiomes = !showBiomes;
                    draw();
                    break;
            }
        }

        private function reset():void {
            // Reset Geography
            featureManager.reset();

            // Reset centers
            for each (var center:Center in centers) {
                center.reset();
            }

            unuseCenters();
        }

        private function onClick(event:MouseEvent):void {
            var center:Center = getCenterClosestToPoint(mouse);
            trace(humanReadableCenter(center));
        }

        private function humanReadableCenter(center:Center):String {
            var str:String = "#" + center.index;
            str += "\n  elevation: " + center.realElevation + " m";
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
