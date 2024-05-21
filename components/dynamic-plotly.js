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
                    showgrid: true, 
                    gridcolor: 'rgba(211, 211, 211, 0.5)', 
                },
                yaxis: {
                    title: this.yTitle,
                    showgrid: true, 
                    gridcolor: 'rgba(211, 211, 211, 0.5)', 
                },
                legend: {
                    orientation: 'h', 
                    x: 0.5, 
                    xanchor: 'center',
                    y: 1.1, 
                    yanchor: 'bottom' 
                },
                margin: { l: 0, r: 0, t: 50, b: 0, pad: 0
                }
            },
            parsedConfig: {}
        }
    }
})
