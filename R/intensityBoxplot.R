# Argument check function
checkArg_intensityBoxplot <- function(MSnSetObj, 
                                      title, 
                                      sampleColours,
                                      colourBy){
    assert_that(is_MSnSet(MSnSetObj))
    assert_that(is.string(colourBy))
    assert_that(is_validMetadataColumn(colourBy, MSnSetObj))
    assert_that(is_validSampleColours(sampleColours, colourBy, MSnSetObj))
    assert_that(is.string(title))
}

#' Intensity Distribution boxplot
#' 
#' Intensity distribution boxplot of all the samples
#' 
#' The column provided to the \code{colourBy} argument will be used to colour
#' the samples. The colours will be determined using the function
#' \code{\link{assignColours}}, alternatively the user may specify a named
#' vector of colours using the \code{sampleColours} argument. The names of the
#' \code{sampleColours} vector should match the unique values in the
#' \code{colourBy} column.
#' 
#' @param MSnSetObj MSnSet; an object of class MSnSet
#' @param title character; title of the plot
#' @param sampleColours character: a named character vector of colors for
#' samples
#' @param colourBy character: column name from pData(MSnSetObj) to use for
#' coloring samples
#' @return An object created by \code{ggplot}
#' @examples
#' 
#' data(human_anno)
#' data(exp3_OHT_ESR1)
#' MSnSet_data <- convertToMSnset(exp3_OHT_ESR1$intensities_qPLEX1, 
#'                                metadata=exp3_OHT_ESR1$metadata_qPLEX1,
#'                                indExpData=c(7:16), 
#'                                Sequences=2, 
#'                                Accessions=6)
#' intensityBoxplot(MSnSet_data, title = "qPLEX_RIME_ER")
#' 
#' # custom colours
#' customCols <- rainbow(length(unique(pData(MSnSet_data)$SampleGroup)))
#' names(customCols) <- unique(pData(MSnSet_data)$SampleGroup)
#' intensityBoxplot(MSnSet_data, 
#'                  title = "qPLEX_RIME_ER", 
#'                  sampleColours = customCols)
#' 
#' @import ggplot2
#' @importFrom Biobase exprs pData
#' @importFrom dplyr across everything filter left_join mutate
#' @importFrom magrittr %>%
#' @importFrom rlang sym
#' @importFrom tidyr pivot_longer
#'
#' @export intensityBoxplot
intensityBoxplot <- function(MSnSetObj, title="", sampleColours=NULL, 
                             colourBy="SampleGroup") {
    if (is.null(sampleColours)) {
        sampleColours <- assignColours(MSnSetObj, colourBy = colourBy)
    }
    checkArg_intensityBoxplot(MSnSetObj, title, sampleColours, colourBy)

    colourBy <- sym(colourBy)
    plotDat <- exprs(MSnSetObj) %>%
        as.data.frame() %>%
        pivot_longer(names_to = "SampleName", 
                     values_to = "Intensity", 
                     everything()) %>%
        mutate(logInt = log2(Intensity)) %>%
        filter(is.finite(logInt)) %>%
        left_join(pData(MSnSetObj), "SampleName") %>%
        mutate(across(!!colourBy, as.factor))
    
    ggplot(plotDat, aes(x = SampleName, y = logInt, fill = !!colourBy)) +
        geom_boxplot(alpha = 0.6) +
        scale_fill_manual(values = sampleColours) +
        labs(x = "Sample", y = "log2(Intensity)", title = title) +
        theme_bw() +
        theme(
            axis.text.x = element_text(angle = 90, hjust = 1),
            plot.title = element_text(hjust = 0.5)
        ) +
        guides(fill = "none")
}

