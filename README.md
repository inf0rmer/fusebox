#Fusebox

Fusebox allows you to employ self-contained, autonomous widgets throughout your app. It is responsible for controlling widget lifecycle and provides several helper methods to widgets that hide platform-specific implementations.

# Getting it
Through Bower. Deets coming soon.

# What's a widget?
Basically, a small module of functionality. Think of a photo gallery, a chat component, or a navigation top bar.

Widgets live in their own folder (this folder is then found inside another folder, "widgets/" by default). They have a main entry point (main.js), which is what gets require()'d by the Fusebox. Inside it's own folder, widgets are free to use whatever structure they wish.

## Registering a widget
Widgets interface with the platform application through events, handled by the Fusebox. The only two required events are ```bootstrap``` and ```unload```, which are triggered when the Fusebox methods ```start``` and ```stop``` are called.

### Registering permissions
The Fusebox keeps a registry of permissions for each widget. These permissions allow the platform to control which widget events are published.

Before a Widget is started, the Fusebox must then register its permissions:
```
Fusebox.permissions.extend({
  "my-widget": {
    bootstrap: true,
    unload: true,
    makePopcorn: true,
    cookRoast: false
  }
});
```

### Starting a Widget
```Fusebox.start``` takes only one mandatory parameter, the Widget's name. The rest are optional and are passed to the callback the Widget registered to it's ```bootstrap``` event.
One of the most common patterns is to initialise a Widget with a CSS/Sizzle selector to inform it of it's assigned element:
```
Fusebox.start("my-widget", "[data-widget='my-widget']")
```
Or add an options hash:
```
Fusebox.start("my-widget", "[data-widget='my-widget']", {myWidgetOption: "Kittens"})
```

### Stopping a widget
```Fusebox.stop``` takes one mandatory parameter, the Widget's name. The rest are optional, just like ```Fusebox.start```. They are passed to the callback registered to the Widget's ```unload``` event.

If you send a valid CSS/Sizzle selector as a second parameter, it is considered to be the widget's main container element. After ```unload``` is processed, that element's HTML is forcefully emptied.

```
Fusebox.stop("my-widget", "[data-widget='my-widget']")
```

### Unloading a widget
Fusebox.stop will only unbind those widget's events and clear its element's HTML. If you're using RequireJS and wish to completely unload the module from memory, use ```Fusebox.unload```:

```
Fusebox.unload("my-widget")
```
