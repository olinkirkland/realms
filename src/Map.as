package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

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
    import geography.Feature;
    import geography.Geography;

    import graph.Center;
    import graph.Corner;
    import graph.Edge;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Map extends UIComponent {
        public static var NUM_POINTS:int = 8000;

        // Map Storage
        public var points:Vector.<Point>;
        public var centers:Vector.<Center>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;
        public var borders:Vector.<Center>;

        // Managers
        private var featureManager:Geography;

        // Generation
        private var seaLevel:Number = .2;

        // Miscellaneous
        private var showOutlines:Boolean = false;
        private var showTerrain:Boolean = true;
        private var showRivers:Boolean = true;
        private var showBiomes:Boolean = false;
        private var showTemperature:Boolean = true;

        public function Map() {
            // Initialize Singletons
            featureManager = Geography.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            // Determine if points file exists
            var pointsData:Object;
            var file:File = File.applicationStorageDirectory.resolvePath("points.json");
            if (file.exists) {
                // Load the points file
                trace("Points file found; Loading points from file")
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                pointsData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
                stream.close();

                points = new Vector.<Point>();
                for each (var pointData:Object in pointsData) {
                    points.push(new Point(pointData.x, pointData.y));
                }
                build();
            } else {
                // Generate points and save them
                trace("Points file not found; Generating new points");
                pickRandomPoints();
                relaxPoints();
                relaxPoints();
                relaxPoints();
                relaxPoints();

                trace("Saving new points file to " + file.url);
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.WRITE);
                stream.writeUTFBytes(JSON.stringify(points));
                stream.close();
            }

            start();

            addEventListener(MouseEvent.CLICK, onClick);
            addEventListener(MouseEvent.RIGHT_CLICK, onRightClick);
            systemManager.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function start(seed:Number = 1):void {
            var time:Number = new Date().time;

            generateHeightMap(seed);
            resolveDepressions();
            defineOceanLandsAndLakes();
            calculateTemperature();
            calculateMoisture();
            calculateRivers();
            defineBiomes();

            draw();

            for each (var feature:Object in featureManager.features) {
                if (feature.type != Feature.RIVER && feature.type != Feature.OCEAN && feature.type != Feature.LAND && feature.type != Feature.LAKE)
                    trace(feature.type, feature.centers.length);
            }

            var timeTaken:Number = ((new Date().time - time) / 1000);
            trace("Generation and drawing finished in " + timeTaken.toFixed(3) + " s");
        }

        private function defineBiomes():void {
            trace("Defining biomes");
            for each (var land:Object in featureManager.getFeaturesByType(Feature.LAND)) {
                var landCenters:Vector.<Center> = land.centers.concat();
                var queue:Array = [];
                while (landCenters.length > 0) {
                    var start:Center = landCenters[0];
                    // Pick a starting biome

                    var currentBiome:String = Biome.determineBiome(start.precipitation, start.temperature);
                    var currentFeature:String = featureManager.registerFeature(currentBiome);
                    featureManager.addCenterToFeature(start, currentFeature);
                    start.biome = currentFeature;
                    start.biomeType = currentBiome;
                    start.used = true;

                    // Fill touching centers
                    queue.push(start);
                    var center:Center;
                    while (queue.length > 0) {
                        center = queue[0];
                        queue.shift();
                        for each (var neighbor:Center in center.neighbors) {
                            if (!neighbor.used && land.centers.indexOf(neighbor) >= 0 && Biome.determineBiome(neighbor.precipitation, neighbor.temperature) == currentBiome) {
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
            for each (var land:Object in featureManager.getFeaturesByType(Feature.LAND)) {
                for each (center in land.centers) {
                    center.precipitation = center.moisture;
                }

                land.centers.sort(sortByHighestElevation);
                for each (center in land.centers) {
                    pour(center, center.neighbors[0]);
                }
            }

            function pour(c:Center, t:Center):void {
                t.precipitation += c.precipitation;
                if (c.precipitation > 8) {
                    var river:String;
                    if (c.hasFeatureType(Feature.RIVER)) {
                        // Extend river
                        var rivers:Object = c.getFeaturesByType(Feature.RIVER);
                        for (var v:String in rivers) {
                            // Pick the longest river to continue
                            if (!river || rivers[v].centers.length > rivers[river].centers.length) {
                                river = v;
                            }
                        }
                        featureManager.addCenterToFeature(t, river);
                    } else {
                        // Start new river
                        river = featureManager.registerFeature(Feature.RIVER);
                        featureManager.addCenterToFeature(c, river);
                        featureManager.addCenterToFeature(t, river);
                    }
                }
            }

            for each (center in centers) {
                center.precipitation = Math.sqrt(center.precipitation) / 2;
                if (center.precipitation > 5)
                    center.precipitation = 5;
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
                        var d:Boolean = center.elevation >= seaLevel;
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
                center.moisture = center.elevation;
            }
        }

        private function calculateTemperature():void {
            for each (var center:Center in centers) {
                // Mapping 0 to 90 latitude for this section of the world
                center.latitudePercent = center.point.y / height;
                center.latitude = center.latitudePercent * 90;
                var temperature:Number = center.latitudePercent;

                // Consider elevation in the temperature (higher places are colder)
                center.temperaturePercent = (temperature - (center.elevation * .3)) / 2;
                center.temperature = (center.temperaturePercent * 40) - 10;
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

            var currentFeature:String = featureManager.registerFeature(Feature.OCEAN);
            featureManager.addCenterToFeature(start, currentFeature);
            start.used = true;
            queue.push(start);

            // Define Ocean
            while (queue.length > 0) {
                var center:Center = queue.shift();
                for each (var neighbor:Center in center.neighbors) {
                    if (!neighbor.used && neighbor.elevation < seaLevel) {
                        featureManager.addCenterToFeature(neighbor, currentFeature);
                        queue.push(neighbor);
                        neighbor.used = true;
                    }
                }
            }

            // Override list borders to be part of the Ocean
            for each (center in borders) {
                featureManager.addCenterToFeature(center, currentFeature);
            }


            // Define Land and Lakes
            var nonOceans:Vector.<Center> = new Vector.<Center>();
            for each (center in centers)
                if (center.features.indexOf(currentFeature) < 0)
                    nonOceans.push(center);

            while (nonOceans.length > 0) {
                start = nonOceans[0];

                var lower:Number;
                var upper:Number;

                // If the elevation of the center is higher than sea level, define it as Land otherwise define it as a Lake
                currentFeature = (start.elevation >= seaLevel) ? featureManager.registerFeature(Feature.LAND) : featureManager.registerFeature(Feature.LAKE);
                if (start.elevation >= seaLevel) {
                    lower = seaLevel;
                    upper = 100;
                } else {
                    lower = -100;
                    upper = seaLevel;
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
                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }

                nonOceans = new Vector.<Center>();
                for each (center in centers)
                    if (center.features.length == 0)
                        nonOceans.push(center);
            }

            unuseCenters();
        }

        private function generateHeightMap(seed:Number = 1):void {
            // Generate a height map
            trace("Generating @seed: " + seed);
            reset();

            var r:Rand = new Rand(seed);
            var w:Number = width / 2;
            var h:Number = height / 2;

            var placementRadius:Number = .5;

            // Add binding island
            addIslandType2(getCenterClosestToPoint(new Point(w, h)), 1, .9, .2, r.next() * 9999);

            // Add big islands
            for (var i:int = 0; i < 10; i++)
                addIslandType1(getCenterClosestToPoint(new Point(w + r.between(-w * placementRadius, w * placementRadius), h + r.between(-h * placementRadius, h * placementRadius))), r.between(.4, .6), r.between(.93, .98), r.between(0, .1), r.next());

            // Add medium islands
            for (i = 0; i < 3; i++)
                addIslandType1(getCenterClosestToPoint(new Point(w + r.between(-w * placementRadius, w * placementRadius), h + r.between(-h * placementRadius, h * placementRadius))), r.between(.2, .4), r.between(.96, .99), r.between(0, .2), r.next());

            // Add small islands
            placementRadius = .6;
            for (i = 0; i < 10; i++)
                addIslandType1(getCenterClosestToPoint(new Point(w + r.between(-w * placementRadius, w * placementRadius), h + r.between(-h * placementRadius, h * placementRadius))), r.between(.2, .4), r.between(.8, .9), r.between(.1, .2), r.next());
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
                    // Toggle temperature
                    showTemperature = !showTemperature;
                    draw();
                    break;
                case Keyboard.R:
                    // Generate with a new seed
                    start(Math.random() * 9999);
                    break;
                case Keyboard.T:
                    // Toggle terrain
                    showTerrain = !showTerrain;
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
            var str:String = "#" + center.index + ", " + center.elevation.toFixed(3) + " elevation";
            str += "\n  temperature: " + center.temperature;
            str += "\n  moisture: " + center.moisture;
            str += "\n  precipitation: " + center.precipitation;
            for each (var f:String in center.features) {
                var feature:Object = featureManager.getFeature(f);
                str += "\n > " + feature.type + " (" + feature.centers.length + ")";
            }

            return str;
        }

        private function onRightClick(event:MouseEvent):void {
        }

        private function get mouse():Point {
            // Return a point referring to the current mouse position
            return new Point(mouseX, mouseY);
        }

        private function addIslandType1(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0, seed:Number = 1):void {
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

        private function addIslandType2(start:Center, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0, seed:Number = 1):void {
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

            var r:Rand = new Rand(1);

            // Clear
            graphics.clear();

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

            if (showOutlines) {
                // Draw outlines
                for each (edge in edges) {
                    // Draw voronoi diagram
                    graphics.lineStyle(1, 0x000000, .2);
                    if (edge.v0 && edge.v1) {
                        graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                        graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                    } else {
                    }
                }
            }

            drawCoastline();

            if (showBiomes) {
                // Draw Biomes
                graphics.lineStyle();
                for each (var biomeName:String in Biome.list) {
                    graphics.beginFill(Biome.colors[biomeName]);
                    for each (var biome:Object in featureManager.getFeaturesByType(biomeName)) {
                        for each (center in biome.centers) {
                            for each (var edge:Edge in center.borders) {
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

            if (showRivers) {
                // Draw rivers
                for each (var river:Object in featureManager.getFeaturesByType(Feature.RIVER)) {
                    var color:uint = getColorFromElevation(0);
                    graphics.moveTo(river.centers[0].point.x, river.centers[0].point.y);
                    graphics.lineStyle(1, color);
                    for each (center in river.centers) {
                        graphics.lineTo(center.point.x, center.point.y);
                        graphics.lineStyle(center.precipitation, color);
                    }
                }
            }

            if (showTemperature) {
                // Draw temperature
                var coldColor:uint = 0x74d6f7;
                var hotColor:uint = 0xf45f42;
                graphics.lineStyle();
                for each (center in centers) {
                    if (center.elevation > seaLevel) {
                        graphics.beginFill(Util.getColorBetweenColors(coldColor, hotColor, center.temperaturePercent));
                        for each (var edge:Edge in center.borders) {
                            if (edge.v0 && edge.v1) {
                                graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                graphics.lineTo(center.point.x, center.point.y);
                                graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            } else {
                            }
                        }
                    }
                }
            }
        }

        private function drawCoastline():void {
            drawFeatureOutlines(Feature.LAND);
            drawFeatureOutlines(Feature.LAKE);
        }

        private function drawFeatureOutlines(featureType:String):void {
            for (var key:String in featureManager.getFeaturesByType(featureType)) {
                var feature:Object = featureManager.features[key];
                graphics.lineStyle(1, feature.color);
                if (feature.type != Feature.OCEAN) {

                    trace("Outlining " + feature.type + "-" + key);

                    for each (var center:Center in feature.centers) {
                        for each (var edge:Edge in center.borders) {
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                if (edge.d0.features.indexOf(key) < 0) {
                                    // Draw a line
                                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                    //graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else if (edge.d1.features.indexOf(key) < 0) {
                                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                    //graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                }
            }
        }


        private function getColorFromFeatures(features:Vector.<String>):uint {
            if (features.length > 0)
                return getColorFromFeature(features[0]);
            return 0x000000;
        }

        private function getColorFromFeature(feature:String):uint {
            return featureManager.getFeature(feature).color;
        }

        private function getColorFromElevation(elevation:Number):uint {
            if (elevation > 1)
                elevation = 1;

            var colors:Array = [0x4890B1, 0x6DC0A8, 0xC9E99F, 0xE6F5A3, 0xFECC7B];

            var preciseIndex:Number = (colors.length - 1) * elevation;
            var index:int = Math.floor(preciseIndex);

            var color:uint = colors[index];
            if (index < colors.length - 1 && elevation >= seaLevel)
                color = Util.getColorBetweenColors(colors[index], colors[index + 1], preciseIndex - index);

            return color;
        }

        public function pickRandomPoints(seed:Number = 1):void {
            // Pick points
            points = new Vector.<Point>;
            var r:Rand = new Rand(seed);
            for (var i:int = 0; i < NUM_POINTS - 4; i++) {
                points.push(new Point(r.next() * width, r.next() * height));
            }
        }

        public function build():void {
            // Setup
            var time:Number = new Date().time;

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

            var timeTaken:Number = ((new Date().time - time) / 1000);
            trace(NUM_POINTS + " point graph built in " + timeTaken.toFixed(3) + " s");
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

    }
}
