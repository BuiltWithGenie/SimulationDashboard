Vue.component("dynamic-plotly", {
    template: `
            <div style="">
                <plotly :data="parsedData" :layout="parsedLayout" :config="parsedConfig"></plotly>
            </div>
            `,

    props: {
        title: String, 
        xColumn: String, 
        dataFrame: Object,
        chartType: String,
        mode: String,
        yTitle: String,
    },

    data() {
        // Generate traces dynamically based on the provided data-frame
        let traces = [];
        for( let columnName in this.dataFrame ) {
            if( columnName == this.xColumn ) {
                continue;
            }
            let trace = {
                x: this.dataFrame[this.xColumn],
                y: this.dataFrame[columnName],
                type: this.chartType, 
                mode: this.mode,
                name: columnName, 
            }
            traces.push( trace )
        }
        
        return {
            parsedData: traces,
            parsedLayout: {
                title: this.title,
                xaxis: {
                    title: this.xColumn,
                    showgrid: true, // Ensures grid lines are visible
                    gridcolor: 'rgba(211, 211, 211, 0.5)', // Light gray color with transparency
                },
                yaxis: {
                    title: this.yTitle,
                    showgrid: true, // Ensures grid lines are visible
                    gridcolor: 'rgba(211, 211, 211, 0.5)', // Light gray color with transparency
                },
                legend: {
                    orientation: 'h', // Sets the legend to horizontal
                    x: 0.5, // Centers the legend
                    xanchor: 'center', // Anchors the legend at its center
                    y: 1.1, // Positions the legend above the chart
                    yanchor: 'bottom' // Anchors the legend at its bottom
                },
                margin: { // Adjusts the chart margins to reduce padding
                    l: 0, // Left margin
                    r: 0, // Right margin
                    t: 50, // Top margin; provide a bit more space for the legend
                    b: 0, // Bottom margin
                    pad: 0 // Padding between the plotting area and the axis lines
                }
            },
            parsedConfig: {}
        }
    }
})
