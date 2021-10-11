#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate sofia parameter file from Nextflow params and defaults
process generate_sofia_parameter_file_template {
    container = params.SOURCE_FINDING_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val image_cube_file

    output:
        stdout emit: file

    script:
        """
        SOFIA_PIPELINE_VERBOSE="${params.SOFIA_PIPELINE_VERBOSE}" \
        SOFIA_PIPELINE_PEDANTIC="${params.SOFIA_PIPELINE_PEDANTIC}" \
        SOFIA_PIPELINE_THREADS="${params.SOFIA_PIPELINE_THREADS}" \
        SOFIA_INPUT_GAIN="${params.SOFIA_INPUT_GAIN}" \
        SOFIA_INPUT_NOISE="${params.SOFIA_INPUT_NOISE}" \
        SOFIA_INPUT_WEIGHTS="${params.SOFIA_INPUT_WEIGHTS}" \
        SOFIA_INPUT_MASK="${params.SOFIA_INPUT_MASK}" \
        SOFIA_INPUT_INVERT="${params.SOFIA_INPUT_INVERT}" \
        SOFIA_FLAG_REGION="${params.SOFIA_FLAG_REGION}" \
        SOFIA_FLAG_CATALOG="${params.SOFIA_FLAG_CATALOG}" \
        SOFIA_FLAG_RADIUS="${params.SOFIA_FLAG_RADIUS}" \
        SOFIA_FLAG_AUTO="${params.SOFIA_FLAG_AUTO}" \
        SOFIA_FLAG_THRESHOLD="${params.SOFIA_FLAG_THRESHOLD}" \
        SOFIA_FLAG_LOG="${params.SOFIA_FLAG_LOG}" \
        SOFIA_SCALENOISE_ENABLE="${params.SOFIA_SCALENOISE_ENABLE}" \
        SOFIA_SCALENOISE_MODE="${params.SOFIA_SCALENOISE_MODE}" \
        SOFIA_SCALENOISE_WINDOWXY="${params.SOFIA_SCALENOISE_WINDOWXY}" \
        SOFIA_SCALENOISE_WINDOWZ="${params.SOFIA_SCALENOISE_WINDOWZ}" \
        SOFIA_SCALENOISE_GRIDXY="${params.SOFIA_SCALENOISE_GRIDXY}" \
        SOFIA_SCALENOISE_GRIDZ="${params.SOFIA_SCALENOISE_GRIDZ}" \
        SOFIA_SCALENOISE_INTERPOLATE="${params.SOFIA_SCALENOISE_INTERPOLATE}" \
        SOFIA_SCALENOISE_SCFIND="${params.SOFIA_SCALENOISE_SCFIND}" \
        SOFIA_SCFIND_ENABLE="${params.SOFIA_SCFIND_ENABLE}" \
        SOFIA_SCFIND_KERNELSXY="${params.SOFIA_SCFIND_KERNELSXY}" \
        SOFIA_SCFIND_KERNELSZ="${params.SOFIA_SCFIND_KERNELSZ}" \
        SOFIA_SCFIND_THRESHOLD="${params.SOFIA_SCFIND_THRESHOLD}" \
        SOFIA_SCFIND_REPLACEMENT="${params.SOFIA_SCFIND_REPLACEMENT}" \
        SOFIA_SCFIND_STATISTIC="${params.SOFIA_SCFIND_STATISTIC}" \
        SOFIA_SCFIND_FLUXRANGE="${params.SOFIA_SCFIND_FLUXRANGE}" \
        SOFIA_THRESHOLD_ENABLE="${params.SOFIA_THRESHOLD_ENABLE}" \
        SOFIA_THRESHOLD_THRESHOLD="${params.SOFIA_THRESHOLD_THRESHOLD}" \
        SOFIA_THRESHOLD_MODE="${params.SOFIA_THRESHOLD_MODE}" \
        SOFIA_THRESHOLD_STATISTIC="${params.SOFIA_THRESHOLD_STATISTIC}" \
        SOFIA_THRESHOLD_FLUXRANGE="${params.SOFIA_THRESHOLD_FLUXRANGE}" \
        SOFIA_LINKER_RADIUSXY="${params.SOFIA_LINKER_RADIUSXY}" \
        SOFIA_LINKER_RADIUSZ="${params.SOFIA_LINKER_RADIUSZ}" \
        SOFIA_LINKER_MINSIZEXY="${params.SOFIA_LINKER_MINSIZEXY}" \
        SOFIA_LINKER_MINSIZEZ="${params.SOFIA_LINKER_MINSIZEZ}" \
        SOFIA_LINKER_MAXSIZEXY="${params.SOFIA_LINKER_MAXSIZEXY}" \
        SOFIA_LINKER_MAXSIZEZ="${params.SOFIA_LINKER_MAXSIZEZ}" \
        SOFIA_LINKER_KEEPNEGATIVE="${params.SOFIA_LINKER_KEEPNEGATIVE}" \
        SOFIA_RELIABILITY_ENABLE="${params.SOFIA_RELIABILITY_ENABLE}" \
        SOFIA_RELIABILITY_THRESHOLD="${params.SOFIA_RELIABILITY_THRESHOLD}" \
        SOFIA_RELIABILITY_SCALEKERNEL="${params.SOFIA_RELIABILITY_SCALEKERNEL}" \
        SOFIA_RELIABILITY_MINSNR="${params.SOFIA_RELIABILITY_MINSNR}" \
        SOFIA_RELIABILITY_PLOT="${params.SOFIA_RELIABILITY_PLOT}" \
        SOFIA_PARAMETER_ENABLE="${params.SOFIA_PARAMETER_ENABLE}" \
        SOFIA_PARAMETER_WCS="${params.SOFIA_PARAMETER_WCS}" \
        SOFIA_PARAMETER_PHYSICAL="${params.SOFIA_PARAMETER_PHYSICAL}" \
        SOFIA_PARAMETER_PREFIX="${params.SOFIA_PARAMETER_PREFIX}" \
        SOFIA_PARAMETER_OFFSET="${params.SOFIA_PARAMETER_OFFSET}" \
        SOFIA_OUTPUT_FILENAME="${params.SOFIA_OUTPUT_FILENAME}" \
        SOFIA_OUTPUT_WRITECATASCII="${params.SOFIA_OUTPUT_WRITECATASCII}" \
        SOFIA_OUTPUT_WRITECATXML="${params.SOFIA_OUTPUT_WRITECATXML}" \
        SOFIA_OUTPUT_WRITECATSQL="${params.SOFIA_OUTPUT_WRITECATSQL}" \
        SOFIA_OUTPUT_WRITENOISE="${params.SOFIA_OUTPUT_WRITENOISE}" \
        SOFIA_OUTPUT_WRITEFILTERED="${params.SOFIA_OUTPUT_WRITEFILTERED}" \
        SOFIA_OUTPUT_WRITEMASK="${params.SOFIA_OUTPUT_WRITEMASK}" \
        SOFIA_OUTPUT_WRITEMASK2D="${params.SOFIA_OUTPUT_WRITEMASK2D}" \
        SOFIA_OUTPUT_WRITERAWMASK="${params.SOFIA_OUTPUT_WRITERAWMASK}" \
        SOFIA_OUTPUT_WRITEMOMENTS="${params.SOFIA_OUTPUT_WRITEMOMENTS}" \
        SOFIA_OUTPUT_WRITECUBELETS="${params.SOFIA_OUTPUT_WRITECUBELETS}" \
        SOFIA_OUTPUT_MARGINCUBELETS="${params.SOFIA_OUTPUT_MARGINCUBELETS}" \
        SOFIA_OUTPUT_OVERWRITE="${params.SOFIA_OUTPUT_OVERWRITE}" \
        python3 -u /app/generate_sofia_params.py \
            -i $image_cube_file \
            -o ${params.SOURCE_FINDING_OUTPUT_DIRECTORY} \
            -f ${params.WORKDIR}/${params.SOFIA_PARAMS_FILE}
        """
}

// Create scripts for running SoFiA via SoFiAX
process s2p_setup {
    container = params.S2P_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val image_cube_file
        val sofia_parameter_file_template

    output:
        val "${params.WORKDIR}/${params.SOFIAX_CONFIG_FILE}", emit: sofiax_config

    script:
        """
        python3 -u /app/s2p_setup.py \
            $image_cube_file \
            $sofia_parameter_file_template \
            ${params.SOURCE_FINDING_RUN_NAME} \
            ${params.SOURCE_FINDING_NODE_SIZE} \
            ${params.WORKDIR}
        """
}

// Another process for updating the sofiax config file database credentials
process credentials {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sofiax_config

    output:
        val sofiax_config, emit: sofiax_config
    
    script:
        """
        python3 /app/database_credentials.py \
            --config $sofiax_config \
            --host ${params.DATABASE_HOST} \
            --name ${params.DATABASE_NAME} \
            --username ${params.DATABASE_USER} \
            --password ${params.DATABASE_PASS}
        """
}

// Read parameter files and create Channel for parallel execution
process get_parameter_files {
    input:
        val s2p_setup
    
    output:
        val parameter_files, emit: parameter_files

    exec:
        parameter_files = file("${params.WORKDIR}/sofia_*.par")
}

// Run source finding application (sofia)
process sofia {
    container = params.SOFIA_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'
    
    input:
        file parameter_file

    output:
        path parameter_file, emit: parameter_file

    script:
        """
        #!/bin/bash
        
        sofia $parameter_file
        """
}

// Write sofia output to database (sofiax)
process sofiax {
    container = params.SOFIAX_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'
    
    input:
        file parameter_file

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofiax -c ${params.WORKDIR}/${params.SOFIAX_CONFIG_FILE} -p $parameter_file
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take: cube

    main:
        // configuration
        generate_sofia_parameter_file_template(cube)
        s2p_setup(cube, generate_sofia_parameter_file_template.out.file)
        credentials(s2p_setup.out.sofiax_config)
        
        // sofia
        get_parameter_files(credentials.out.sofiax_config)
        sofia(get_parameter_files.out.parameter_files.flatten())

        // sofiax
        sofiax(sofia.out.parameter_file)
}

// ----------------------------------------------------------------------------------------

