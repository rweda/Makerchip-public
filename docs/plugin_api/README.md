# Makerchip Plugin API

## Overview

The Makerchip Plugin API enables third-party platforms to embed the Makerchip IDE and interact with it programmatically. This allows you to integrate TL-Verilog circuit design, simulation, and visualization capabilities into your own web applications. It also enables AI agentic control of the IDE.

This documentation details the classes and methods available for integration.

**See also**

- the <a href="../../../../../module/IDE/plugin_example.html" target="_blank">Example Use Page</a>
- the `IdePlugin` class and its methods for detailed API
- the **Release Notes** (extra) for version history and migration notes

## Getting Started

To embed Makerchip in your application:

1. Create a container element in your HTML for the IDE:
   ```html
   <div id="my-makerchip"></div>
   ```

2. Use it out of the box:

   ```javascript
   // Import the plugin code
   import IdePlugin from 'https://makerchip.com/dist/makerchip-plugin.js';
   
   // Initialize the IDE
   await IdePlugin.create('my-makerchip');
   ```

3. Or, customize its behavior and interact with it:

   ```javascript
   import IdePlugin from 'https://makerchip.com/dist/makerchip-plugin.js';
   
   // Extend IdePlugin with custom behavior
   class MyIDE extends IdePlugin {
     onReady() {
       // Your initialization
       console.log("IDE ready!");
       // Enable UI, set up event handlers, etc.
     }
     
     onCodeChange() {
       // Save to localStorage, enable save button, etc.
     }

     onTermsAccepted(acceptedAt) {
       // Remember the user's acceptance of the Makerchip terms (see below).
       localStorage.setItem('makerchipTermsAcceptedAt', acceptedAt);
     }
   }
   
   // Initialize the IDE
   const ide = await MyIDE.create('my-makerchip', {
     termsAcceptedAt: localStorage.getItem('makerchipTermsAcceptedAt')
   });
   
   // Now you can interact with the IDE
   const { code } = await ide.getCode();  // Get current (default) code
   ```

   The IDE asks the user to accept the Makerchip Terms of Service and Privacy Policy. Remembering
   the acceptance, as above, avoids asking on every page load. By passing `termsAcceptedAt`, you
   attest that the user accepted (see the `termsAcceptedAt` option of `IdePlugin`).

4. Create other derived IDEs and instantiate as many of them as you like:

   ```html
   <div id="my-makerchip-2"></div>
   <div id="my-other-makerchip"></div>
   ```

   ```javascript
   class MyOtherIDE extends IdePlugin {
     onReady() {
       console.log("Second IDE ready!");
     }
   }
   
   const ide2 = await MyIDE.create('my-makerchip-2');
   const ide3 = await MyOtherIDE.create('my-other-makerchip');
   ```
