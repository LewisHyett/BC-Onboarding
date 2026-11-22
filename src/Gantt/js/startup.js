// Creates the chart container and tells AL the control can receive data.
(function () {
    var root = document.getElementById('controlAddIn');
    var chart = document.createElement('div');
    chart.id = 'onbGantt';
    chart.className = 'onb-gantt';
    root.appendChild(chart);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
})();
