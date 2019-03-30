package geography {
    import graph.Center;

    import mx.utils.UIDUtil;

    public class Geography {
        private static var _instance:Geography;
        public var features:Object = {};
        public var colors:Object = {};

        // Features
        public static var OCEAN:String = "ocean";
        public static var LAND:String = "land";
        public static var LAKE:String = "lake";
        public static var RIVER:String = "river";

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

        public function registerFeature(type:String):String {
            var id:String = UIDUtil.createUID();

            features[id] = {id: id, type: type, centers: new Vector.<Center>(), color: colors[type]};

            return id;
        }

        public function addCenterToFeature(center:Center, feature:String):void {
            center.features[feature] = features[feature];
            features[feature].centers.push(center);
        }

        public function getFeature(id:String):Object {
            return features[id];
        }

        public function getFeaturesByType(type:String):Object {
            var obj:Object = {};
            for each (var feature:Object in features) {
                if (feature.type == type) {
                    obj[feature.id] = feature;
                }
            }
            return obj;
        }
    }
}