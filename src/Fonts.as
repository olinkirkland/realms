package {
    public class Fonts {
        [Embed(source="assets/fonts/Chomsky.otf",
                fontName="Chomsky",
                mimeType="application/x-font",
                advancedAntiAliasing="true",
                embedAsCFF="false")]
        private var chomsky:Class;

        public static var elaborateTitle:String = "Chomsky";
    }
}
