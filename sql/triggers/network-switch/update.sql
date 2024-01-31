DELIMITER $$
USE `dashboard`$$
DROP trigger IF EXISTS `update_network_switch`$$

CREATE trigger `update_network_switch` BEFORE UPDATE ON NetworkSwitch
	FOR EACH ROW	
		BEGIN
			SET @highestPortNumberInUse = (SELECT MAX(port_number) FROM NetworkSwitchPort WHERE switch_id = NEW.id);
			SET @numOfUsedPorts = (SELECT COUNT(id) FROM NetworkSwitchPort WHERE switch_id = NEW.id);
			SET @numOfVlansOnSwitch = (SELECT COUNT(id) FROM NetworkSwitchVlan WHERE switch_id = NEW.id);
			
			-- Makes sure the new number of ports isn't less than the current amount of ports that exists
			IF NEW.num_of_ports < @numOfUsedPorts THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Cannot update the number of ports for the network switch to less than what currently exists";
			END IF;

			-- Makes sure the new number of ports isn't less than the highest port number that exists
			IF NEW.num_of_ports < @highestPortNumberInUse THEN
				SET @errorMessage = CONCAT("Cannot update the number of ports to less than what's currently in use. The highest port in use is Port #", @highestPortNumberInUse);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @errorMessage;
			END IF;

			-- Makes sure the network switch is vlan capable if it has any registered vlans
			IF OLD.vlan_capable = 1 AND NEW.vlan_capable = 0 AND @numOfVlansOnSwitch > 0 THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Cannot update the network switch as incapable of VLANs when there are VLANs registered to it";
			END IF;
		END$$
DELIMITER ;