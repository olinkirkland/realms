package labels {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

    import flash.display.Sprite;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;

    import graph.Cell;
    import graph.Corner;
    import graph.Edge;

    public class RegionLabel extends MapLabel {
        private var points:Vector.<Point>;
        private var rect:Rectangle;

        private var cells:Vector.<Cell>;
        private var edges:Vector.<Edge>;
        private var corners:Vector.<Corner>;

        public function RegionLabel(region:Object) {
            super();

            var borderPoints:Array = Util.removeDuplicatesFromArray(region.simpleBorderPoints);
            rect = Util.getBoundsFromPoints(borderPoints);

            // Simplify border points by only picking every 5th one
            var simpleBorderPoints:Array = [];
            var i:int = 0;
            for each(var borderPoint:Point in borderPoints) {
                i++;
                if (i % 5 == 0)
                    simpleBorderPoints.push(borderPoint);
            }

            borderPoints = simpleBorderPoints;

            rect.x -= 5;
            rect.y -= 5;
            rect.width += 10;
            rect.height += 10;

            /**
             * Build
             */
            points = Vector.<Point>(borderPoints);
            build();

            // Find corners touching the edge
            var queue:Array = [];
            for each (var corner:Corner in corners) {
                if (corner.border)
                    queue.push(corner);
            }

            graphics.lineStyle();
            while (queue.length > 0) {
                var current:Corner = queue.shift();
                for each (var protrude:Edge in current.protrudes) {
                    if (!protrude.used) {
                        protrude.used = true;
                        protrude.outer = true;

                        // Find if it intersects the region borders
                        var intersect:Point;
                        for (i = 1; i < borderPoints.length; i++) {
                            intersect = Util.getIntersectBetweenTwoLineSegments(protrude.v0.point, protrude.v1.point, borderPoints[i], borderPoints[i - 1]);
                            if (intersect)
                                break;
                        }

                        if (!intersect)
                            intersect = Util.getIntersectBetweenTwoLineSegments(protrude.v0.point, protrude.v1.point, borderPoints[0], borderPoints[i - 1]);

                        if (!intersect)
                            queue.push(protrude.v0 == current ? protrude.v1 : protrude.v0);
                    }
                }
            }

            var perimeter:Array = [];
            for each (var edge:Edge in edges) {
                if (edge.v0 && edge.v1 && !edge.outer) {
                    // Prep the edge for Dijkstra
                    edge.voronoiDistance = Util.getDistanceBetweenTwoPoints(edge.v0.point, edge.v1.point);
                    edge.used = false;

                    graphics.lineStyle(.1, 0x000000);
                    //graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                    //graphics.lineTo(edge.v1.point.x, edge.v1.point.y);

                    // Determine if the corners are perimeters
                    if (isCornerPerimeter(edge.v0))
                        perimeter.push(edge.v0);
                    if (isCornerPerimeter(edge.v1))
                        perimeter.push(edge.v1);
                }
            }

            function isCornerPerimeter(corner:Corner):Boolean {
                var count:int = 0;
                for each (protrude in corner.protrudes)
                    if (!protrude.outer)
                        count++;
                return count <= 1;
            }

            // Dijkstra
            // For each perimeter node, calculate the shortest distance to each other perimeter node
            var bestPath:Object;
            for each (var start:Corner in perimeter) {
                // Soft reset corners
                for each (corner in corners) {
                    corner.used = false;
                    corner.cameFrom = null;
                    corner.priority = 0;
                    corner.costSoFar = 0;
                }

                var queue:Array = [start];
                start.costSoFar = 0;

                // Loop through queue
                while (queue.length > 0) {
                    var current:Corner = queue.shift();

                    for each (edge in current.protrudes) {
                        if (!edge.outer) {
                            var next:Corner = current == edge.v0 ? edge.v1 : edge.v0;
                            var nextCost = edge.voronoiDistance;
                            var newCost:Number = current.costSoFar + nextCost;
                            if (!next.used || newCost < next.costSoFar) {
                                next.used = true;
                                next.costSoFar = newCost;
                                next.cameFrom = current;
                                next.priority = newCost;

                                // Place 'next' in the queue
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

                for each (var stop:Corner in perimeter) {
                    if (stop != start) {
                        var sinuosity:Number = stop.costSoFar / Util.getDistanceBetweenTwoPoints(start.point, stop.point);
                        var fitness:Number = stop.costSoFar / Math.pow(sinuosity, 4);
                        if (!bestPath || (fitness > bestPath.fitness)) {
                            // Get the shortest route between start and stop
                            var corner:Corner = stop;
                            var path:Array = [stop];
                            while (corner != start && corner.cameFrom) {
                                path.push(corner.cameFrom);
                                corner = corner.cameFrom;
                            }

                            bestPath = {};
                            bestPath.fitness = fitness;
                            bestPath.distance = Util.getDistanceBetweenTwoPoints(start.point, stop.point);
                            bestPath.nodes = path.reverse();
                            bestPath.size = stop.costSoFar;
                        }
                    }
                }
            }

            // Draw the longest path
            if (bestPath) {
                graphics.lineStyle(.1, 0x000000);
                var arr:Array = [];
                graphics.moveTo(bestPath.nodes[0].point.x, bestPath.nodes[0].point.y);
                for (i = 0; i < bestPath.nodes.length; i++) {
                    arr.push(bestPath.nodes[i].point);
                }

                if (arr.length > 2) {
                    var first:Point = arr[0];
                    var last:Point = arr[arr.length - 1];

                    // Pick the point in arr for which a line drawn perpendicular to the slope of the average is longest
                    var furthestPoint:Point;
                    var furthestDistance:Number = 0;
                    for (i = 1; i < arr.length - 1; i++) {
                        var dist:Number = Util.getDistanceBetweenLineSegmentAndPoint(first, last, arr[i]);
                        if (!furthestPoint || dist > furthestDistance) {
                            furthestPoint = arr[i];
                            furthestDistance = dist;
                        }
                    }

                    // Make the control point happen halfway through with the same distance
                    var midPoint:Point = new Point((first.x + last.x) / 2, (first.y + last.y) / 2);
                    var angle:Number = Util.getAngleBetweenTwoPoints(first, last);

                    var controlPoint:Point = new Point();
                    controlPoint.x = midPoint.x + (Math.cos(Util.degreesToRadians(angle - 90)) * furthestDistance);
                    controlPoint.y = midPoint.y + (Math.sin(Util.degreesToRadians(angle - 90)) * furthestDistance);

                    // If a line from the furthest point to the control point crosses the line between first and last, translate the control point over the line
                    if (Util.getIntersectBetweenTwoLineSegments(controlPoint, furthestPoint, first, last)) {
                        controlPoint.x = midPoint.x + (Math.cos(Util.degreesToRadians(angle + 90)) * furthestDistance);
                        controlPoint.y = midPoint.y + (Math.sin(Util.degreesToRadians(angle + 90)) * furthestDistance);
                    }

                    var spread:Number = 12;
                    var numPoints:int = Util.getDistanceBetweenTwoPoints(first, last) / spread;
                    var textPoints:Array = [first];
                    for (i = 0; i < numPoints; i++) {
                        var val:Number = i / numPoints;
                        if (val > 0 && val < 1) {
                            var p:Point = Util.quadraticBezierPoint(val, first, last, controlPoint);
                            textPoints.push(p);
                        }
                    }

                    var flip:Boolean = angle < -90 || angle > 90;

                    var i:int = (textPoints.length - (region.name.length));

                    if (i < 0)
                        return;

                    i /= 2;

                    var letters:Array = region.name.split('');
                    if (flip)
                        letters = letters.reverse();

                    for (var n:int = 0; n < textPoints.length; n++) {
                        p = textPoints[n];
                        graphics.lineStyle(.1, Util.getColorBetweenColors(0xff0000, 0x0000ff, n / textPoints.length));
                        graphics.drawCircle(p.x, p.y, 5);
                    }

                    var j:int = letters.length - 1;
                    for (i; i < textPoints.length; i++) {
                        var textPoint:Point = textPoints[i];

                        var txt:TextField = new TextField();
                        var format:TextFormat = new TextFormat(Fonts.regular, 20, 0x000000);
                        txt.defaultTextFormat = format;
                        txt.embedFonts = true;
                        txt.selectable = false;

                        txt.text = letters[j];
                        txt.autoSize = TextFieldAutoSize.LEFT;
                        txt.width = txt.textWidth;

                        var spr:Sprite = new Sprite();
                        spr.addChild(txt);
                        addChild(spr);

                        spr.x = textPoint.x;
                        spr.y = textPoint.y;
                        txt.x = -spr.width / 2;
                        txt.y = -spr.height / 2;

                        if (i == 0) {
                            // First element, take angle of angleAfter
                            angle = Util.getAngleBetweenTwoPoints(textPoint, textPoints[i + 1]);
                        } else if (i == textPoints.length - 1) {
                            // Last element, take angle of angleBefore
                            angle = Util.getAngleBetweenTwoPoints(textPoint, textPoints[i - 1]);
                        } else {
                            // Any other element, take the average of angleBefore and angleAfter
                            var angleBefore:Number = Util.getAngleBetweenTwoPoints(textPoint, textPoints[i - 1]);
                            var angleAfter:Number = Util.getAngleBetweenTwoPoints(textPoint, textPoints[i + 1]);
                            angle = (angleBefore + angleAfter) / 2;
                        }

                        spr.rotation = angle;
                        if (flip)
                            spr.rotation += 180;

                        // Iterate the letter index
                        j--;
                        if (j < 0)
                            break;
                    }
                }
            }
        }

        public function build():void {
            // Setup
            var voronoi:Voronoi = new Voronoi(points, null, rect);
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
                corner.border = corner.point.x == rect.x || corner.point.x == rect.x + rect.width || corner.point.y == rect.y || corner.point.y == rect.y + rect.height;

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
                edge.delaunayAngle = Util.getAngleBetweenTwoPoints(edge.d0.point, edge.d1.point);

            if (edge.v0 && edge.v1)
                edge.voronoiAngle = Util.getAngleBetweenTwoPoints(edge.v0.point, edge.v1.point);

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
    }
}