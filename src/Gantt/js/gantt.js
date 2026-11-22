// Read-only Gantt chart for onboarding lines, drawn as SVG with no external libraries.
// Labels are set through textContent, so line descriptions can't inject markup.

var ONB_ROW = 26;
var ONB_HEADER = 40;
var ONB_INDENT = 14;
var ONB_DAY_MS = 86400000;
var ONB_STATUS_NAMES = ['Not Started', 'In Progress', 'Completed', 'Not Applicable'];
var ONB_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
var onbLastData = null;
var onbResizeTimer = null;
var onbZoom = 'fit';
// Pixels per day for each zoom level; 'fit' squeezes the whole plan into the visible width.
var ONB_ZOOMS = [
    { key: 'fit', caption: 'Fit', dayWidth: 0 },
    { key: 'day', caption: 'Days', dayWidth: 40 },
    { key: 'week', caption: 'Weeks', dayWidth: 14 },
    { key: 'month', caption: 'Months', dayWidth: 4 }
];

function onbParseDate(text) {
    if (!text) { return null; }
    var parts = text.split('-');
    if (parts.length !== 3) { return null; }
    return Date.UTC(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
}

function onbSvg(tag, attrs, parent) {
    var el = document.createElementNS('http://www.w3.org/2000/svg', tag);
    for (var key in attrs) {
        if (Object.prototype.hasOwnProperty.call(attrs, key)) { el.setAttribute(key, attrs[key]); }
    }
    if (parent) { parent.appendChild(el); }
    return el;
}

function onbFormatDay(ms) {
    var d = new Date(ms);
    return d.getUTCDate() + ' ' + ONB_MONTHS[d.getUTCMonth()];
}

// The control's own width; BC may not have laid out the frame yet, so fall back to the window.
function onbAvailableWidth(chart) {
    var width = chart.clientWidth;
    if (!width && document.documentElement) { width = document.documentElement.clientWidth; }
    if (!width) { width = window.innerWidth || 800; }
    return width;
}

// Days between axis labels, so labels (about 50px wide) never overlap.
function onbLabelStep(dayWidth) {
    var steps = [1, 2, 7, 14, 28];
    for (var i = 0; i < steps.length; i++) {
        if (steps[i] * dayWidth >= 50) { return steps[i]; }
    }
    return 56;
}

function onbMessage(chart, text) {
    var div = document.createElement('div');
    div.className = 'empty';
    div.textContent = text;
    chart.appendChild(div);
}

// Toolbar with the zoom buttons, and a scroll area below it that holds the chart.
function onbLayout() {
    var chart = document.getElementById('onbGantt');
    if (!chart) { return null; }
    // BC sizes the frame, not our div: take the frame's height so the scroll area can scroll.
    chart.style.height = (window.innerHeight || 400) + 'px';
    while (chart.firstChild) { chart.removeChild(chart.firstChild); }

    var toolbar = document.createElement('div');
    toolbar.className = 'toolbar';
    ONB_ZOOMS.forEach(function (zoom) {
        var button = document.createElement('button');
        button.type = 'button';
        button.textContent = zoom.caption;
        button.className = zoom.key === onbZoom ? 'active' : '';
        button.addEventListener('click', function () {
            onbZoom = zoom.key;
            onbRender();
        });
        toolbar.appendChild(button);
    });
    // Browser full screen, offered only where the frame BC puts the control in allows it.
    if (document.fullscreenEnabled && document.documentElement.requestFullscreen) {
        var full = document.createElement('button');
        full.type = 'button';
        full.className = 'fullscreen';
        full.textContent = document.fullscreenElement ? 'Exit full screen' : 'Full screen';
        full.addEventListener('click', function () {
            if (document.fullscreenElement) {
                document.exitFullscreen();
            } else {
                document.documentElement.requestFullscreen();
            }
        });
        toolbar.appendChild(full);
    }
    chart.appendChild(toolbar);

    var scroll = document.createElement('div');
    scroll.className = 'scroll';
    scroll.style.height = Math.max((window.innerHeight || 400) - 36, 100) + 'px';
    chart.appendChild(scroll);
    return scroll;
}

function onbRender() {
    var chart = onbLayout();
    if (!chart) { return; }
    var lines = onbLastData;

    if (!lines || lines.length === 0) {
        onbMessage(chart, 'No lines yet. Select Modules to add tasks.');
        return;
    }

    var minStart = null;
    var maxEnd = null;
    lines.forEach(function (line) {
        line.startMs = onbParseDate(line.start);
        line.endMs = onbParseDate(line.end);
        if (line.startMs !== null && line.endMs === null) { line.endMs = line.startMs; }
        if (line.endMs !== null && line.startMs === null) { line.startMs = line.endMs; }
        if (line.startMs !== null) {
            if (minStart === null || line.startMs < minStart) { minStart = line.startMs; }
            if (maxEnd === null || line.endMs > maxEnd) { maxEnd = line.endMs; }
        }
    });

    if (minStart === null) {
        onbMessage(chart, 'No planned dates yet. Set a Start Date and choose Plan Dates, or enter dates on the tasks.');
        return;
    }

    // One day of margin on each side.
    minStart -= ONB_DAY_MS;
    maxEnd += ONB_DAY_MS;
    var days = Math.round((maxEnd - minStart) / ONB_DAY_MS) + 1;
    var totalWidth = onbAvailableWidth(chart) - 4;
    var labelWidth = Math.max(220, Math.min(380, Math.round(totalWidth * 0.28)));
    // Fit fills the remaining width (at least 6px a day); the other zoom levels scroll sideways.
    var dayWidth = Math.max(6, (totalWidth - labelWidth - 8) / days);
    ONB_ZOOMS.forEach(function (zoom) {
        if (zoom.key === onbZoom && zoom.dayWidth > 0) { dayWidth = zoom.dayWidth; }
    });
    var width = labelWidth + Math.ceil(days * dayWidth) + 8;
    var height = ONB_HEADER + lines.length * ONB_ROW + 4;

    var svg = onbSvg('svg', { width: width, height: height }, chart);

    // Alternate row shading makes long plans easier to follow.
    lines.forEach(function (line, index) {
        if (index % 2 === 1) {
            onbSvg('rect', { x: 0, y: ONB_HEADER + index * ONB_ROW, width: width, height: ONB_ROW, 'class': 'row-alt' }, svg);
        }
    });

    var step = onbLabelStep(dayWidth);
    for (var i = 0; i < days; i++) {
        var x = labelWidth + i * dayWidth;
        if (i % step === 0) {
            onbSvg('line', { x1: x, y1: ONB_HEADER - 8, x2: x, y2: height, 'class': 'grid' }, svg);
            var tick = onbSvg('text', { x: x + 3, y: ONB_HEADER - 14, 'class': 'axis' }, svg);
            tick.textContent = onbFormatDay(minStart + i * ONB_DAY_MS);
        } else if (dayWidth >= 12) {
            onbSvg('line', { x1: x, y1: ONB_HEADER, x2: x, y2: height, 'class': 'grid-minor' }, svg);
        }
    }
    onbSvg('line', { x1: 0, y1: ONB_HEADER - 1, x2: width, y2: ONB_HEADER - 1, 'class': 'grid' }, svg);

    var now = new Date();
    var today = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
    if (today >= minStart && today <= maxEnd) {
        var tx = labelWidth + ((today - minStart) / ONB_DAY_MS) * dayWidth;
        onbSvg('line', { x1: tx, y1: ONB_HEADER - 8, x2: tx, y2: height, 'class': 'today' }, svg);
    }

    lines.forEach(function (line, index) {
        var y = ONB_HEADER + index * ONB_ROW;
        var indent = line.indent || 0;
        var label = onbSvg('text', {
            x: 6 + indent * ONB_INDENT,
            y: y + ONB_ROW / 2 + 4,
            'class': line.isGroup ? 'label group' : 'label'
        }, svg);
        var text = line.description || '';
        var maxChars = Math.max(8, Math.floor((labelWidth - 12 - indent * ONB_INDENT) / 7));
        label.textContent = text.length > maxChars ? text.substring(0, maxChars - 1) + '…' : text;
        onbSvg('title', {}, label).textContent = text;

        if (line.startMs === null) { return; }
        var bx = labelWidth + ((line.startMs - minStart) / ONB_DAY_MS) * dayWidth;
        var bw = Math.max(((line.endMs - line.startMs) / ONB_DAY_MS + 1) * dayWidth - 1, 3);
        var bar;
        if (line.isGroup) {
            bar = onbSvg('rect', { x: bx, y: y + 10, width: bw, height: 6, rx: 1, 'class': 'bar-group' }, svg);
        } else {
            bar = onbSvg('rect', { x: bx, y: y + 5, width: bw, height: ONB_ROW - 10, rx: 3, 'class': 'status-' + (line.status || 0) }, svg);
        }
        onbSvg('title', {}, bar).textContent = text + '\n' + onbFormatDay(line.startMs) + ' – ' + onbFormatDay(line.endMs) +
            (line.isGroup ? '' : '\n' + (ONB_STATUS_NAMES[line.status] || ''));
    });
}

window.SetData = function (lines) {
    onbLastData = lines || [];
    onbRender();
    // Draw again once BC has finished sizing the frame.
    setTimeout(onbRender, 200);
};

document.addEventListener('fullscreenchange', function () { onbRender(); });

window.addEventListener('resize', function () {
    clearTimeout(onbResizeTimer);
    onbResizeTimer = setTimeout(onbRender, 100);
});
