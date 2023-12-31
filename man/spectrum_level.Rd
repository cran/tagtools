% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spectrum_level.R
\name{spectrum_level}
\alias{spectrum_level}
\title{Compute the spectrum level of a signal x.}
\usage{
spectrum_level(x, nfft, sampling_rate, w, nov)
}
\arguments{
\item{x}{A vector containing the signal to be processed. For signals with multiple channels, each channel should be in a column of x.}

\item{nfft}{The length of the fft to use. Choose a power of two for fastest operation. Default value is 512.}

\item{sampling_rate}{The sampling rate of x in Hz. Default value is 1. sampling_rate is the vector of frequencies at which SL is calculated.}

\item{w}{The window length. The default value is nfft. If w<nfft, each segment of w samples is zero-padded to nfft.}

\item{nov}{The number of samples to overlap each segment. The default value is half of the window length.}
}
\value{
A list with 2 elements:
\itemize{
\item{\strong{SL: }}The spectrum level at each frequency in dB RMS re root-Hz. The spectrum is single-sided and extends to sampling_rate/2. The reference level is 1.0 (i.e., white noise with unit variance will have a spectrum level of 3-10*log10(sampling_rate). The 3dB is because both the negative and positive spectra are added together so that the total power in the signal is the same as the total power in the spectrum.
\item{\strong{freq: }} The vector of frequencies at which SL is calculated.
}
}
\description{
This function is used to compute the spectrum level of a signal x.
}
\note{
The spectrum is single-sided and extends to sampling_rate/2. The reference level is 1.0 (i.e., white noise with unit variance will have a spectrum level of 3-10*log10(sampling_rate). The 3dB is because both the negative and positive spectra are added together so that the total power in the signal is the same as the total power in the spectrum.
}
\examples{
BW <- beaked_whale
list <- spectrum_level(x = BW$P$data, nfft = 4, sampling_rate = BW$P$sampling_rate)

}
