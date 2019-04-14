package labels {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class RegionLabel extends MapLabel {
        public function RegionLabel(region:Object) {
            var background:Sprite = new Sprite();
            addChild(background);

            var format:TextFormat = new TextFormat(Fonts.regular, 12, 0xffffff);
            var txt:TextField = new TextField();
            txt.embedFonts = true;
            txt.defaultTextFormat = format;
            txt.selectable = false;
            txt.text = region.name;
            txt.autoSize = TextFieldAutoSize.LEFT;
            txt.width = txt.textWidth;
            txt.height = txt.textHeight;
            txt.x = -txt.width / 2;
            txt.y = -txt.height / 2;
            addChild(txt);

            var hPadding:int = 1;
            var vPadding:int = 3;
            background.graphics.beginFill(0x000000, .7);
            background.graphics.drawRoundRect(txt.x - hPadding, txt.y - vPadding, txt.width + 2 * hPadding, txt.height + 2 * vPadding, 15, 15);
            background.graphics.endFill();
        }
    }
}
