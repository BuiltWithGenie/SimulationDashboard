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
    watch: {
        dataFrame: {
            deep: true,
            handler(newValue, oldValue) {
                console.log("dataFrame changed: ", newValue, oldValue);
                this.parsedData = this.getDynamicTraces();
            }
        }
    },

    methods: {
        getDynamicTraces() {
            let traces = [];
            for (let columnName in this.dataFrame) {
                if (columnName == this.xColumn) {
                    continue;
                }
                let trace = {
                    x: this.dataFrame[this.xColumn],
                    y: this.dataFrame[columnName],
                    type: this.chartType,
                    mode: this.mode,
                    name: columnName,
                }
                traces.push(trace)
            }
            return traces;
        }
    },

    data() {
        return {
            parsedData: this.getDynamicTraces(),
            parsedLayout: {
                title: this.title,
                xaxis: {
                    title: this.xColumn,
                    showgrid: true,
                    gridcolor: 'rgba(230, 230, 230, 0.1)', // Even lighter grid color
                    tickmode: 'auto',
                },
                yaxis: {
                    title: this.yTitle,
                    showgrid: true,
                    gridcolor: 'rgba(230, 230, 230, 0.1)', // Match x-axis for consistency
                },
                legend: {
                    orientation: 'h',
                    x: 0.5,
                    xanchor: 'center',
                    y: 1.1,
                    yanchor: 'bottom'
                },
                margin: {
                    l: 30, r: 0, t: 50, b: 20, pad: 0
                }
            },
            parsedConfig: {}
        }
    }
});
