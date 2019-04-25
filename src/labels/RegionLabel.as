package labels {
    import com.nodename.Delaunay.Voronoi;

    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class RegionLabel extends MapLabel {
        private var voronoi:Voronoi;

        public function RegionLabel(region:Object) {
            super();

            var borderPoints:Array = Util.removeDuplicatesFromArray(region.simpleBorderPoints);
            var rect:Rectangle = Util.getBoundsFromPoints(borderPoints);

            rect.x -= 5;
            rect.y -= 5;
            rect.width += 10;
            rect.height += 10;

            var v0:Object;
            var v1:Object;

            // Draw bounds
            graphics.lineStyle(1, 0x0000ff);
            graphics.drawRect(rect.x, rect.y, rect.width, rect.height);

            // Draw the region borders
            graphics.moveTo(borderPoints[0].x, borderPoints[0].y);
            for each (var borderPoint:Point in borderPoints) {
                graphics.lineTo(borderPoint.x, borderPoint.y);
            }
            graphics.lineTo(borderPoints[0].x, borderPoints[0].y);

            // Create voronoi graph
            voronoi = new Voronoi(Vector.<Point>(borderPoints), null, rect);
            for each (var p:Point in borderPoints)
                voronoi.region(p);

            // Create a graph of the voronoi edge points
            var libEdges:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();
            var pointsDictionary:Object = [];
            for each (var libEdge:com.nodename.Delaunay.Edge in libEdges) {
                var p0:Point = libEdge.voronoiEdge().p0;
                var p1:Point = libEdge.voronoiEdge().p1;
                if (p0 && !pointsDictionary[p0])
                    pointsDictionary[p0] = {point: p0, neighbors: getNeighboringEdgePoints(p0)};
                if (p1 && !pointsDictionary[p1])
                    pointsDictionary[p1] = {point: p1, neighbors: getNeighboringEdgePoints(p1)};
            }

            var queue:Array = [];
            // Add points on the border rectangle to queue
            // they are guaranteed not to lie within the region's outline
            for each (var t:Object in pointsDictionary)
                if (t.point.x == rect.x || t.point.x == rect.x + rect.width || t.point.y == rect.y || t.point.y == rect.y + rect.height)
                    queue.push(t);

            // Loop through queue
            while (queue.length > 0) {
                var current:Object = queue.shift();
                current.used = true;
                for each (var neighbor:Object in current.neighbors) {
                    if (!pointsDictionary[neighbor].used)
                        queue.push(pointsDictionary[neighbor]);
                }
            }

            for each (t in pointsDictionary) {
                if (t.used)
                    graphics.lineStyle(1, 0xff0000);
                graphics.lineStyle(1, 0xffffff);
                graphics.moveTo(t.point.x, t.point.y);
                for each (var u:Point in t.neighbors) {
                    var v:Object = pointsDictionary[u];
                    graphics.lineTo(v.point.x, v.point.y);
                }
            }
        }

        private function getNeighboringEdgePoints(p:Point):Array {
            var neighbors:Array = [];
            var libEdges:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.Delaunay.Edge in libEdges) {
                var p0:Point = libEdge.voronoiEdge().p0;
                var p1:Point = libEdge.voronoiEdge().p1;
                if (p0 && p1) {
                    if (p0 == p)
                        neighbors.push(p1);
                    else if (p1 == p)
                        neighbors.push(p0);
                }
            }
            return neighbors;
        }
    }
}
