package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import graph.Center;
    import graph.Corner;
    import graph.Edge;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Map extends UIComponent {
        public static var NUM_POINTS:int = 200;

        // Map Storage
        public var points:Vector.<Point>;
        public var centers:Vector.<Center>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;


        public function Map() {
            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            pickRandomPoints();
            build();
            for (var i:int = 0; i < 3; i++)
                relaxPoints();

            draw();
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

        private function draw():void {
            // Clear
            graphics.clear();

            // Draw Centers
            graphics.lineStyle(1, 0x000000, .1);
            for each (var center:Center in centers) {
                // Fill polygons
                var a:Number = .5 + Math.abs(Math.random() - .5);
                for each (var edge:Edge in center.borders) {
                    graphics.beginFill(0x0000ff, a);
                    //a += .05;
                    if (edge.v0 && edge.v1) {
                        graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                        graphics.lineTo(center.point.x, center.point.y);
                        graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                    } else {
                    }
                }
            }
            graphics.endFill();

            // Draw outlines
            for each (var edge:Edge in edges) {
                if (edge.v0 && edge.v1) {
//                    graphics.lineStyle(1, 0x000000);
//                    graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
//                    graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                } else {
                }
            }

            // Draw Corners
            graphics.lineStyle(1, 0xff0000);
            for each (var corner:Corner in corners) {
                if (corner.border)
                    graphics.drawCircle(corner.point.x, corner.point.y, 5);
            }
        }

        public function pickRandomPoints():void {
            // Pick points
            points = new Vector.<Point>;
            var r:Rand = new Rand(1);
            for (var i:int = 0; i < NUM_POINTS; i++) {
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
            }

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

            var timeTaken:Number = ((new Date().time - time) / 1000);
            trace("Finished (" + NUM_POINTS + " points) in " + timeTaken.toFixed(3) + " s");
            trace("   " + (NUM_POINTS / timeTaken).toFixed(3) + " points per second");
        }
    }
}
