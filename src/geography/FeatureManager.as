package geography {
    import graph.Center;

    import mx.utils.UIDUtil;

    public class FeatureManager {
        private static var _instance:FeatureManager;
        public var features:Object = {};
        public var colors:Object = {};

        public function FeatureManager() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            // Setup
            colors[Feature.OCEAN] = 0x000000;
            colors[Feature.LAND] = 0x000000;
            colors[Feature.LAKE] = 0x387089;
        }

        public static function getInstance():FeatureManager {
            if (!_instance)
                new FeatureManager();
            return _instance;
        }

        public function reset():void {
            features = {};
        }

        public function registerFeature(type:String):String {
            var id:String = UIDUtil.createUID();

            features[id] = {type: type, centers: new Vector.<Center>(), color: colors[type]};
            if (type == Feature.OCEAN)
                features[id].color = 0x4890B1;

            return id;
        }

        public function addCenterToFeature(center:Center, feature:String):void {
            center.features.push(feature);
            features[feature].centers.push(center);
        }

        public function getFeature(id:String):Object {
            return features[id];
        }

        public function getFeaturesByType(type:String):Object {
            var obj:Object = {};
            for (var key:String in features) {
                if (features[key].type == type) {
                    obj[key] = features[key];
                }
            }

            return obj;
        }
    }
}