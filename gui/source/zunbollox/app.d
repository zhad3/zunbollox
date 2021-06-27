import std.stdio;

import tkd.tkdapplication;
import zencoding.windows949 : fromWindows949;

static void openUrl(string url)
{
    import std.process : execute;

    version (Posix)
    {
        execute(["xdg-open", url]);
    }
    else version (Windows)
    {
        execute(["start", url]);
    }
    else version (OSX)
    {
        execute(["open", url]);
    }
}

class CustomYScrollBar : YScrollBar
{
    import tkd.widget.common.yscrollcommand;

    this(UiElement parent = null)
    {
        super(parent);
    }

    public auto attachWidgets(this T, S)(IYScrollable!(S) scrollableWidget1, IYScrollable!(S) scrollableWidget2)
    {
        import tkd.widget.widget;

        auto widget1 = cast(Widget) scrollableWidget1;
        auto widget2 = cast(Widget) scrollableWidget2;

        this._tk.eval("%s configure -command {syncScroll {%s %s} yview}", this.id, widget1.id, widget2
                .id);

        return cast(T) this;
    }

    import tkd.widget.common.command;

    mixin Command;
}

class CustomXScrollBar : XScrollBar
{
    import tkd.widget.common.xscrollcommand;

    this(UiElement parent = null)
    {
        super(parent);
    }

    public auto attachWidgets(this T, S)(IXScrollable!(S) scrollableWidget1, IXScrollable!(S) scrollableWidget2)
    {
        import tkd.widget.widget;

        auto widget1 = cast(Widget) scrollableWidget1;
        auto widget2 = cast(Widget) scrollableWidget2;

        this._tk.eval("%s configure -command {syncScroll {%s %s} xview}", this.id, widget1.id, widget2
                .id);

        return cast(T) this;
    }

    import tkd.widget.common.command;

    mixin Command;
}

class CustomText : Text
{
    this(UiElement parent = null)
    {
        super(parent);
    }

    import tkd.widget.scrollbar;

    public auto attachYScrollBars(YScrollBar scrollbar1, YScrollBar scrollbar2)
    {
        this._tk.eval("%s configure -yscrollcommand {setScroll %s %s}", this.id, scrollbar1.id, scrollbar2
                .id);

        return this;
    }

    public auto attachXScrollBars(XScrollBar scrollbar1, XScrollBar scrollbar2)
    {
        this._tk.eval("%s configure -xscrollcommand {setScroll %s %s}", this.id, scrollbar1.id, scrollbar2
                .id);

        return this;
    }
}

class Application : TkdApplication
{

private:
    Window aboutWindow;
    CustomText widget_cp949;
    CustomText widget_utf8;
    CustomXScrollBar xscroll_cp949;
    CustomYScrollBar yscroll_cp949;
    CustomXScrollBar xscroll_utf8;
    CustomYScrollBar yscroll_utf8;

    void showOpenFile(CommandArgs /*args*/ )
    {
        auto dialog = new OpenFileDialog("Open a text file")
            .setMultiSelection(false)
            .setDefaultExtension("*")
            .addFileType("{{All files} {*}}")
            .setInitialDirectory("~")
            .show();

        string filename = dialog.getResult();

        this.unbolloxFile(filename);
    }

    void unbolloxFile(string filename)
    {
        if (filename.length == 0)
        {
            return;
        }

        import std.stdio : File;
        import std.utf : validate, UTFException, toUTF8;
        import std.exception : ErrnoException;

        File file;
        scope (exit)
            file.close();

        char[] buffer;

        try
        {
            file = File(filename);

            import core.stdc.stdio : SEEK_END, SEEK_SET;

            file.seek(0, SEEK_END);
            auto filesize = file.tell();
            file.seek(0, SEEK_SET);
            buffer = new char[filesize];

            file.rawRead(buffer);
        }
        catch (ErrnoException err)
        {
            new MessageDialog("Error")
                .setIcon(MessageDialogIcon.error)
                .setMessage("Error opening file")
                .setDetailMessage(err.msg)
                .show();
            return;
        }

        try
        {
            validate(buffer);
            this.widget_cp949.clear().insertText(0, 0, buffer.toUTF8);
            this.unbolloxEx();
        }
        catch (UTFException)
        {
            // Assume latin1/ascii text

            string decoded;
            import std.encoding : transcode, Latin1String;

            transcode(cast(Latin1String) buffer, decoded); // :^)

            this.widget_cp949.clear().insertText(0, 0, decoded);
            this.unbolloxEx();
        }
    }

    void hideAbout(CommandArgs /*args*/ )
    {
        aboutWindow.withdraw();
    }

    void showAbout(CommandArgs /*args*/ )
    {
        if (aboutWindow !is null)
        {
            aboutWindow.deiconify();
            aboutWindow.raise();
            aboutWindow.focus();
        }
        else
        {
            aboutWindow = new Window(this.mainWindow, "About")
                .setMinSize(300, 230)
                .setMaxSize(300, 230)
                .setResizable(false, false)
                .setProtocolCommand(WindowProtocol.deleteWindow, &this.hideAbout);

            auto frame = new Frame(aboutWindow, 2, ReliefStyle.groove)
                .pack(5, 5, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

            new Label(frame, "zunbollox gui 1.0.1").setFont("arial", 12, FontStyle.bold).pack(5);
            new Label(frame, "https://github.com/zhad3/zunbollox").pack(5)
                .setFont("arial", 10, FontStyle.underline)
                .setForegroundColor(Color.blue3)
                .setCursor(Cursor.hand2)
                .bind("<Button-1>", delegate(CommandArgs /*args*/ ) {
                    openUrl("https://github.com/zhad3/zunbollox");
                });
            new Label(frame, "Copyright (C) 2021, zhad3").pack(5);
            new Separator(frame).pack(10, 0, GeometrySide.top, GeometryFill.x);
            new Label(frame, "This GUI is written with tkd, a Tcl/Tk wrapper").pack(5);
            new Label(frame, "https://github.com/nomad-software/tkd").pack(5)
                .setFont("arial", 10, FontStyle.underline)
                .setForegroundColor(Color.blue3)
                .setCursor(Cursor.hand2)
                .bind("<Button-1>", delegate(CommandArgs /*args*/ ) {
                    openUrl("https://github.com/nomad-software/tkd");
                });

            new Button(frame, "OK")
                .setCommand(&this.hideAbout)
                .pack(10);

            aboutWindow.focus();
        }
    }

    void createMenu()
    {
        auto menuBar = new MenuBar(this.mainWindow);

        new Menu(menuBar, "File", 0)
            .addEntry("Open file...", &this.showOpenFile)
            .addSeparator()
            .addEntry("Quit", &this.exitCommand);

        new Menu(menuBar, "Help", 0)
            .addEntry("About...", &this.showAbout);
    }

    void exitCommand(CommandArgs /*args*/ )
    {
        this.exit();
    }

    void unbollox(CommandArgs /*args*/ )
    {
        this.unbolloxEx();
    }

    void unbolloxEx()
    {
        import std.string : representation, chop;
        import std.utf : toUTF8;
        import std.encoding : Latin1String, transcode;
        import zencoding.windows949 : fromWindows949;

        // The input is utf-8, convert it back to latin1 (ascii)
        Latin1String latin1;
        this.widget_cp949.getText().transcode(latin1);

        const yview = this.widget_cp949.getYView();
        const xview = this.widget_cp949.getXView();

        this.widget_utf8
            .clear()
            .insertText(0, 0, fromWindows949(latin1).toUTF8.chop);

        this.widget_utf8.setYView(yview[0]);
        this.widget_utf8.setXView(xview[0]);
    }

    void createScrollSyncProcedure()
    {
        import tkd.interpreter.tk;

        // https://stackoverflow.com/a/11518512
        Tk.getInstance()
            .eval("proc syncScroll {widgets args} { foreach w $widgets {$w {*}$args} }");
        Tk.getInstance().eval("proc setScroll {s s2 args} {
                $s set {*}$args
                $s2 set {*}$args
                {*}[$s cget -command] moveto [lindex [$s get] 0]
                }");
    }

protected:
    override void initInterface()
    {
        this.createScrollSyncProcedure();

        this.mainWindow.setTitle("zunbollox gui")
            .setMinSize(600, 300);

        this.createMenu();

        auto frame = new Frame(2, ReliefStyle.groove)
            .pack(5, 5, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true)
            .configureGeometryColumn(1, 1)
            .configureGeometryRow(0, 1);

        auto frame_cp949 = new Frame(0, ReliefStyle.flat).pack()
            .configureGeometryColumn(0, 1)
            .configureGeometryRow(1, 1);
        auto frame_utf8 = new Frame(0, ReliefStyle.flat).pack()
            .configureGeometryColumn(0, 1)
            .configureGeometryRow(1, 1);

        new Label(frame_utf8, "Output: UTF-8 text")
            .grid(0, 0, 0, 5, 2, 1);
        new Label(frame_cp949, "Input: Windows code page 949 text")
            .grid(0, 0, 0, 5, 2, 1);

        this.widget_utf8 = new CustomText(frame_utf8)
            .setWrapMode(TextWrapMode.none)
            .setHeight(0);

        this.widget_cp949 = new CustomText(frame_cp949)
            .setWrapMode(TextWrapMode.none)
            .setHeight(0);
        //.bind("<KeyRelease>", &this.unbollox);

        this.yscroll_utf8 = new CustomYScrollBar(frame_utf8)
            .attachWidgets(this.widget_utf8, this.widget_cp949)
            .grid(1, 1, 0, 0, 1, 1, "nes");
        this.xscroll_utf8 = new CustomXScrollBar(frame_utf8)
            .attachWidgets(this.widget_utf8, this.widget_cp949)
            .grid(0, 2, 0, 0, 1, 1, "esw");

        this.yscroll_cp949 = new CustomYScrollBar(frame_cp949)
            .attachWidgets(this.widget_cp949, this.widget_utf8)
            .grid(1, 1, 0, 0, 1, 1, "nes");
        this.xscroll_cp949 = new CustomXScrollBar(frame_cp949)
            .attachWidgets(this.widget_cp949, this.widget_utf8)
            .grid(0, 2, 0, 0, 1, 1, "esw");

        this.widget_utf8
            .attachYScrollBars(this.yscroll_utf8, this.yscroll_cp949)
            .attachXScrollBars(this.xscroll_utf8, this.xscroll_cp949)
            .grid(0, 1, 0, 0, 1, 1, "nesw");

        this.widget_cp949
            .attachYScrollBars(this.yscroll_cp949, this.yscroll_utf8)
            .attachXScrollBars(this.xscroll_cp949, this.xscroll_utf8)
            .grid(0, 1, 0, 0, 1, 1, "nesw");

        new PanedWindow(frame, Orientation.horizontal)
        .grid(0, 0, 0, 0, 3, 1, "nesw")
            .addPane(frame_cp949)
            .addPane(frame_utf8);

        new Button(frame, "Clear").grid(0, 1, 5, 0, 1, 1, "w")
            .setCommand(delegate(CommandArgs /*args*/ ) {
                this.widget_utf8.clear();
                this.widget_cp949.clear();
            });

        new Button(frame, "Unbollox!").grid(1, 1, 5, 0, 1, 1, "")
            .setCommand(&this.unbollox);

        new Button(frame, "Copy").grid(2, 1, 5, 0, 1, 1, "e")
            .setCommand(delegate(CommandArgs /*args*/ ) {
                import tkd.interpreter.tk : Tk;

                Tk.getInstance().eval("clipboard clear");
                Tk.getInstance().eval("clipboard append [%s get 0.0 end]", this.widget_utf8.id);
            });

        new SizeGrip().pack(0, 0, GeometrySide.bottom, GeometryFill.none, AnchorPosition.southEast);

    }
}

version(Windows)
{
    import core.runtime;
    import core.sys.windows.windows;
    
    extern(Windows)
    int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
        LPSTR lpCmdLine, int nCmdShow)
    {
        int result;

        try
        {
            Runtime.initialize();
            result = start(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
            Runtime.terminate();
        }
        catch (Throwable e)
        {
            import std.string : toStringz;
            
            MessageBoxA(null, e.toString().toStringz(), null, MB_ICONEXCLAMATION);
            result = 0;
        }
        
        return result;
    }

    int start(HINSTANCE hInstance, HINSTANCE hPrevInstance,
        LPSTR lpCmdLine, int nCmdShow)
    {
        auto app = new Application();
        app.run();

        return 1;
    }
}
else 
{
    void main()
    {
        auto app = new Application();
        app.run();
    }
}
