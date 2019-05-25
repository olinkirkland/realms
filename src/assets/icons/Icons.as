package assets.icons {
    import flash.display.Bitmap;

    import generation.towns.Town;

    public class Icons {
        [Embed(source="tradeTown.png")]
        public static const TradeTown:Class;

        [Embed(source="ironMine.png")]
        public static const IronMine:Class;

        [Embed(source="saltMine.png")]
        public static const SaltMine:Class;

        [Embed(source="stoneQuarry.png")]
        public static const StoneQuarry:Class;

        [Embed(source="loggingTown.png")]
        public static const LoggingTown:Class;

        [Embed(source="fishingTown.png")]
        public static const FishingTown:Class;

        [Embed(source="city.png")]
        public static const City:Class;

        public static function townIconFromType(townType:String):Bitmap {
            if (townType == Town.TRADE)
                return new TradeTown();
            if (townType == Town.STONE)
                return new StoneQuarry();
            if (townType == Town.SALT)
                return new SaltMine();
            if (townType == Town.IRON)
                return new IronMine();
            if (townType == Town.HARBOR)
                return new FishingTown();
            if (townType == Town.WOOD)
                return new LoggingTown();
            return null;
        }
    }
}
