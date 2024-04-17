function VERA = removeNonExistantChannels(VERA,theseElectrodesDontExist)

VERA.electrodeLabels(theseElectrodesDontExist) = [];
VERA.electrodeDefinition.Annotation(theseElectrodesDontExist) = [];
VERA.electrodeDefinition.Label(theseElectrodesDontExist) = [];
VERA.electrodeDefinition.DefinitionIdentifier(theseElectrodesDontExist) = []; 

VERA.electrodeNames(theseElectrodesDontExist) = [];

VERA.tala.electrodes(theseElectrodesDontExist,:) = [];
VERA.tala.activations(theseElectrodesDontExist) = [];
VERA.tala.trielectrodes(theseElectrodesDontExist,:) = [];
VERA.SecondaryLabel(theseElectrodesDontExist) = [];

end
