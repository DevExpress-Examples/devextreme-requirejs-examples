# DevExtreme with RequireJS and jQuery example

This [jQuery](http://jquery.com/) example displays DevExtreme widgets that load only the required modules. The application contains a button (a [dxButton](https://js.devexpress.com/Documentation/ApiReference/UI_Components/dxButton/) widget). When you click this button, an [alert dialog](https://js.devexpress.com/Documentation/ApiReference/Common/Utils/ui/dialog/#alertmessageHtml_title) appears. The example uses [RequireJS](http://requirejs.org/) to load scripts on demand.

## Getting Started

1. Clone the repository.
 ``` text  
 git clone https://github.com/DevExpress-Examples/devextreme-requirejs-examples.git
 ```

2. Go to the project folder.
 ``` text
 cd requirejs-jquery
 ```

3. Install the required modules. This command will also convert the DevExtreme package to the AMD module format by using the npm postinstall script.
 ``` text
 npm install
 ```

4. Open the `index.html` file in your browser.

## Resources

For detailed information on modularity, see the [DevExtreme Modularity Guide](http://js.devexpress.com/Documentation/Guide/Common/Modularity).
