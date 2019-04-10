package generation {
    import graph.Cell;

    import mx.utils.UIDUtil;

    public class Geography {
        private static var _instance:Geography;

        // Generation
        public var features:Object = {};
        public var colors:Object = {};

        // Features
        public static var OCEAN:String = "ocean";
        public static var LAND:String = "land";
        public static var LAKE:String = "lake";
        public static var RIVER:String = "river";
        public static var ESTUARY:String = "estuary";
        public static var CONFLUENCE:String = "confluence";
        public static var GLADE:String = "glade";
        public static var HAVEN:String = "haven";

        public function Geography() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            // Setup
            colors[OCEAN] = 0x4890B1;
            colors[LAND] = 0x387089;
            colors[LAKE] = 0x387089;
        }

        public static function getInstance():Geography {
            if (!_instance)
                new Geography();
            return _instance;
        }

        public function reset():void {
            features = {};
        }

        public function registerFeature(featureType:String):String {
            var id:String = UIDUtil.createUID();

            features[id] = {id: id, type: featureType, cells: new Vector.<Cell>()};

            return id;
        }

        public function addCellToFeature(cell:Cell, feature:String):void {
            cell.features[feature] = features[feature];
            features[feature].cells.push(cell);
        }

        public function removeCellFromFeature(cell:Cell, feature:String):void {
            delete cell.features[feature];
            features[feature].cells.removeAt(features[feature].cells.indexOf(cell));
        }

        public function getFeaturesByType(featureType:String):Object {
            var obj:Object = {};
            for each (var feature:Object in features) {
                if (feature.type == featureType) {
                    obj[feature.id] = feature;
                }
            }
            return obj;
        }
    }
}