controladdin "Onb. Gantt"
{
    Scripts = 'src/Gantt/js/gantt.js';
    StartupScript = 'src/Gantt/js/startup.js';
    StyleSheets = 'src/Gantt/js/gantt.css';

    RequestedHeight = 520;
    MinimumHeight = 300;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    /// <summary>
    /// Raised once the chart is loaded and can receive data.
    /// </summary>
    event ControlReady();

    /// <summary>
    /// Draws the chart. Each element: lineNo, description, indent, isGroup, start, end (yyyy-mm-dd or ''), status (0..3).
    /// </summary>
    procedure SetData(Lines: JsonArray);
}
