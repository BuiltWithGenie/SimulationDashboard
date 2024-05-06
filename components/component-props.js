Vue.component("component-props", {
    template: `
            <div style="height: 400px; overflow-y: auto;">
                <q-expansion-item
                        v-for="comp in components"
                        :key="comp['name']"
                        :label="comp['name']"
                        class="q-mb-sm b-2 border-white"
                        style="border-width:1px;border-radius:5px;border-color:steelblue;"
                        expand-separator
                        default-closed>

                    <q-expansion-item
                            v-if="Object.keys(comp['parameters']).length > 0"
                            label="Parameters" icon="tune" class="b-2">
                        <div v-for="(val, p) in comp['parameters']" :key="p" class="bg-sky-900 pb-2">
                            <q-input
                                    style="width:100%;max-width:80%"
                                    class="ml-10"
                                    :id="'param-' + comp + '-' + p"
                                    :label="p"
                                    v-model="comp['parameters'][p]"
                                    type="number">
                            </q-input>
                        </div>
                    </q-expansion-item>

                    <q-expansion-item
                            v-if="Object.keys(comp['states']).length > 0"
                            label="Initial state values" icon="timeline">
                        <div v-for="(val, p) in comp['states']" :key="p" class="bg-sky-900 pb-2">
                            <q-input
                                    style="width:100%;max-width:80%"
                                    class="ml-10"
                                    :id="'state-' + comp + '-' + p"
                                    :label="p + '(t)'"
                                    v-model="comp['states'][p]"
                                    type="number">
                            </q-input>
                        </div>
                    </q-expansion-item>

                    <q-expansion-item label="Equations" icon="functions" >
                        <div class="shortColumn" class="bg-sky-900 pb-2 pt-2 pl-1" style="overflow-x:auto">
                            <span class="shortColumn" style="max-width:100%" v-katex="{'options':{'errorColor':'#CC0000','displayMode':true,'throwOnError':false,'maxExpand':500,'strict':'warn','maxSize':'Infinity','allowedProtocols':[]},'expression':comp['equations']}"></span>
                        </div>
                    </q-expansion-item>
                </q-expansion-item>
            </div>
                      `,
    props: {
        components: {
            type: Object,
            default: { "aaa": "bbb" }
        }
    },
    data() {
        return {

        }
    }
})
