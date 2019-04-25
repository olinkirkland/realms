package labels {
    import com.nodename.Delaunay.Voronoi;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;

    public class RegionLabel extends MapLabel {
        private var voronoi:Voronoi;

        public function RegionLabel(region:Object) {
            super();

            var borderPoints:Array = Util.removeDuplicatesFromArray(region.simpleBorderPoints);
            var rect:Rectangle = Util.getBoundsFromPoints(borderPoints);
            var i:int;

            trace(borderPoints.length + " ->");
            var simpleBorderPoints:Array = [];
            i = 0;
            for each(var borderPoint:Point in borderPoints) {
                i++;
                if (i % 5 == 0)
                    simpleBorderPoints.push(borderPoint);
            }

            borderPoints = simpleBorderPoints;
            trace("-> " + borderPoints.length);

            rect.x -= 5;
            rect.y -= 5;
            rect.width += 10;
            rect.height += 10;

            // Draw bounds
            graphics.lineStyle(.1, 0xff0000);
            graphics.drawRect(rect.x, rect.y, rect.width, rect.height);

            // Draw the region borders
            graphics.moveTo(borderPoints[0].x, borderPoints[0].y);
            for each (var borderPoint:Point in borderPoints) {
                graphics.lineTo(borderPoint.x, borderPoint.y);
                graphics.drawCircle(borderPoint.x, borderPoint.y, 2);
                graphics.moveTo(borderPoint.x, borderPoint.y);
            }
            graphics.lineTo(borderPoints[0].x, borderPoints[0].y);

            // Create voronoi graph
            voronoi = new Voronoi(Vector.<Point>(borderPoints), null, rect);
            for each (var p:Point in borderPoints)
                voronoi.region(p);

            // Create a graph of the voronoi edge points
            var pointsDictionary:Dictionary = new Dictionary();
            var libEdges:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.Delaunay.Edge in libEdges) {
                var p0:Point = libEdge.voronoiEdge().p0;
                var p1:Point = libEdge.voronoiEdge().p1;

                if (p0 && !pointsDictionary[p0.toString()])
                    pointsDictionary[p0.toString()] = {point: p0, neighbors: getNeighboringEdgePoints(p0)};
                if (p1 && !pointsDictionary[p1.toString()])
                    pointsDictionary[p1.toString()] = {point: p1, neighbors: getNeighboringEdgePoints(p1)};
            }

            // Draw background lines
            var arr:Array = new Array();
            for each (t in pointsDictionary)
                arr.push(t);

            setTimeout(drawPointAndNeighborsAtIndex, 1000);

            function drawPointAndNeighborsAtIndex(m:int = 0):void {
                var t:Object = arr[m];
                var color:uint = Util.randomColor();
                graphics.lineStyle(1, color);
                graphics.drawCircle(t.point.x, t.point.y, 3);
                for each (var u:Point in t.neighbors) {
                    var v:Object = pointsDictionary[u.toString()];
                    graphics.moveTo(t.point.x, t.point.y);
                    graphics.lineTo(v.point.x, v.point.y);
                }

                setTimeout(drawPointAndNeighborsAtIndex, 1000, [m + 1]);
            }

            for each (t in pointsDictionary) {
                graphics.lineStyle(.1, 0x000000, .1);
                graphics.drawCircle(t.point.x, t.point.y, 2);
                graphics.moveTo(t.point.x, t.point.y);
                for each (var u:Point in t.neighbors) {
                    var v:Object = pointsDictionary[u.toString()];
                    graphics.lineTo(v.point.x, v.point.y);
                }
            }

            // Add points on the border rectangle to queue
            // they are guaranteed not to lie within the region's outline
            var queue:Array = [];
            for each (var t:Object in pointsDictionary)
                if (t.point.x == rect.x || t.point.x == rect.x + rect.width || t.point.y == rect.y || t.point.y == rect.y + rect.height)
                    queue.push(t);

            // Loop through queue
            graphics.lineStyle(0x000000);
            var usedCombinations:Object = {};

            while (queue.length > 0) {
                var current:Object = queue.shift();
                var n:int = 0;

                var txt:TextField = new TextField();
                txt.text = "" + current.neighbors.length;
                txt.x = current.point.x;
                txt.y = current.point.y;
                addChild(txt);

                for each (var neighbor:Point in current.neighbors) {
                    n++;
                    var combinationKey:String = generateCombinationKey(current.point, neighbor);
                    if (usedCombinations[combinationKey]) {
                        // Combination was previously used
                        graphics.lineStyle(.1, 0x0000ff);
                        graphics.moveTo(current.point.x, current.point.y);
                        graphics.lineTo(neighbor.x, neighbor.y);
                    } else {
                        // Combination is not used yet
                        // Mark the combination as used
                        usedCombinations[combinationKey] = true;
                        queue.push(pointsDictionary[neighbor.toString()]);
                        graphics.lineStyle(.1, 0x000000);
                        graphics.drawCircle(current.point.x, current.point.y, 2);
                        graphics.moveTo(current.point.x, current.point.y);
                        graphics.lineTo(neighbor.x, neighbor.y);

                        // If the combination crosses a region boundary mark it
                        var intersect:Point;
                        for (i = 1; i < borderPoints.length; i++) {
                            intersect = Util.getIntersect(borderPoints[i - 1], borderPoints[i], current.point, neighbor);
                            if (intersect) break;
                        }
                        if (!intersect)
                            intersect = Util.getIntersect(borderPoints[i - 1], borderPoints[0], current.point, neighbor);

                        if (intersect) {
                            graphics.lineStyle();
                            graphics.beginFill(0x0000ff);
                            graphics.drawCircle(intersect.x, intersect.y, 2);
                            graphics.endFill();
                        }
                    }
                }
            }
        }

        private function generateCombinationKey(p1:Point, p2:Point):String {
            return (p1.x > p2.x) ? p1.toString() + p2.toString() : p2.toString() + p1.toString();
        }

        private function getNeighboringEdgePoints(p:Point):Array {
            var neighbors:Array = [];
            var lib:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();

            for each (var edge:com.nodename.Delaunay.Edge in lib) {
                var p0:Point = edge.voronoiEdge().p0;
                var p1:Point = edge.voronoiEdge().p1;

                if (p0 && p1) {
                    if (p.equals(p0))
                        neighbors.push(p1);
                    if (p.equals(p1))
                        neighbors.push(p0);
                }
            }

            trace(neighbors.length);
            return neighbors;
        }
    }
}