package graph {
    import flash.geom.Point;

    public class Corner {
        public var index:int;

        // Location
        public var point:Point;

        // A set of polygons touching this corne
        public var touches:Vector.<Center>;

        // A set of edges touching the corner
        public var protrudes:Vector.<Edge>;

        // A set of corners connected to this one
        public var adjacent:Vector.<Corner>;

        // Is it at the edge of the map?
        public var border:Boolean;

        public function Corner() {
            touches = new Vector.<Center>();
            protrudes = new Vector.<Edge>();
            adjacent = new Vector.<Corner>();
        }
    }
}
