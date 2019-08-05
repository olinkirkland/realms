package {
    public class Fonts {
        [Embed(source="assets/fonts/Chomsky.otf",
                fontName="fancy",
                mimeType="application/x-font",
                advancedAntiAliasing="true",
                embedAsCFF="false")]
        private var chomsky:Class;

        [Embed(source="assets/fonts/Alice-Regular.ttf",
                fontName="regular",
                mimeType="application/x-font",
                advancedAntiAliasing="true",
                embedAsCFF="false")]
        private var alice:Class;

        public static var fancy:String = "fancy";
        public static var regular:String = "regular";
    }
}
