package generation {
    import generation.towns.HarborTown;
    import generation.towns.IronMine;
    import generation.towns.LoggingTown;
    import generation.towns.SaltMine;
    import generation.towns.StoneQuarry;
    import generation.towns.Town;
    import generation.towns.TradeTown;

    import graph.Cell;

    import mx.utils.UIDUtil;

    public class Civilization {
        private static var _instance:Civilization;

        // Generation
        public var citiesById:Object = {};
        public var citiesByCell:Object = {};
        public var townsById:Object = {};
        public var townsByCell:Object = {};
        public var regions:Object = {};
        public var roads:Object = {};
        public var seaRoutes:Object = {};
        public var crossroads:Object = {};

        public function Civilization() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance():Civilization {
            if (!_instance)
                new Civilization();
            return _instance;
        }

        public function get cities():Object {
            return citiesById;
        }

        public function get towns():Object {
            return townsById;
        }

        public function reset():void {
            regions = {};

            citiesById = {};
            citiesByCell = {};
            townsById = {};
            townsByCell = {};

            roads = {};
            seaRoutes = {};
            crossroads = {};
        }

        public function registerCity(cell:Cell):String {
            var id:String = UIDUtil.createUID();
            var city:City = new City(cell, id);
            cell.city = city;

            citiesById[id] = city;
            citiesByCell[cell] = city;

            return id;
        }

        public function registerTown(cell:Cell, type:String):String {
            var id:String = UIDUtil.createUID();

            var town:Town;
            switch (type) {
                case Town.IRON:
                    town = new IronMine(cell, id);
                    break;
                case Town.SALT:
                    town = new SaltMine(cell, id);
                    break;
                case Town.STONE:
                    town = new StoneQuarry(cell, id);
                    break;
                case Town.TRADE:
                    town = new TradeTown(cell, id);
                    break;
                case Town.WOOD:
                    town = new LoggingTown(cell, id);
                    break;
                case Town.HARBOR:
                    town = new HarborTown(cell, id);
                    break;
                default:
                    break;
            }

            cell.town = town;

            townsById[id] = town;
            townsByCell[cell] = town;

            return id;
        }

        public function registerRegion():String {
            var id:String = UIDUtil.createUID();

            regions[id] = new Region(id, new Vector.<Cell>());

            return id;
        }

        public function addCellToRegion(cell:Cell, region:String, influence:int):void {
            if (cell.region) {
                var cells:Vector.<Cell> = regions[cell.region].cells;
                cells.removeAt(cells.indexOf(cell));
            }

            cell.region = regions[region].id;
            cell.regionInfluence = influence;
            regions[region].cells.push(cell);
        }


        public function registerCrossroad(cell:Cell):String {
            var id:String = UIDUtil.createUID();

            cell.crossroad = true;
            crossroads[id] = {id: id, cell: cell};

            return id;
        }

        public function registerRoad(startingCell:Cell, endingCell:Cell):String {
            var id:String = UIDUtil.createUID();

            roads[id] = {id: id, startingCell: startingCell, endingCell: endingCell};

            return id;
        }

        public function addCellsToRoad(cells:Vector.<Cell>, road:String):void {
            roads[road].cells = cells;
        }

        public function registerSeaRoute(startingCell:Cell, endingCell:Cell):String {
            var id:String = UIDUtil.createUID();

            seaRoutes[id] = {id: id, startingCell: startingCell, endingCell: endingCell};

            return id;
        }

        public function addCellsToSeaRoute(cells:Vector.<Cell>, seaRoute:String):void {
            seaRoutes[seaRoute].cells = cells;
        }
    }
}