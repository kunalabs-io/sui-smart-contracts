module kai_leverage::debt_bag {
    use sui::bag::{Self, Bag};

    use std::type_name::{Self, TypeName};

    use kai_leverage::debt::{Self, DebtShareBalance};

    const EAssetShareTypeMismatch: u64 = 0;
    /// The requested asset or share type does not exist in the debt bag.
    const ETypeDoesNotExist: u64 = 1;

    const ENotEnough: u64 = 2;

    public struct Info has store {
        asset_type: TypeName,
        share_type: TypeName,
        amount: u128,
    }

    public struct DebtBag has key, store {
        id: UID,
        infos: vector<Info>,
        bag: Bag,
    }

    public struct Key has copy, store, drop {
        t: TypeName,
        st: TypeName,
    }

    /* ================= DebtBag ================= */

    public fun empty(ctx: &mut TxContext): DebtBag {
        DebtBag {
            id: object::new(ctx),
            infos: vector::empty(),
            bag: bag::new(ctx),
        }
    }

    fun get_asset_idx_opt(self: &DebtBag, asset_type: &TypeName): Option<u64> {
        let mut i = 0;
        let n = vector::length(&self.infos);
        while (i < n) {
            let info = &self.infos[i];
            if (&info.asset_type == asset_type) {
                return option::some(i)
            };
            i = i + 1;
        };
        option::none()
    }

    fun get_share_idx_opt(self: &DebtBag, share_type: &TypeName): Option<u64> {
        let mut i = 0;
        let n = self.infos.length();
        while (i < n) {
            let info = &self.infos[i];
            if (&info.share_type == share_type) {
                return option::some(i)
            };
            i = i + 1;
        };
        option::none()
    }

    fun get_share_idx(self: &DebtBag, share_type: &TypeName): u64 {
        let idx_opt = get_share_idx_opt(self, share_type);
        assert!(option::is_some(&idx_opt), ETypeDoesNotExist);
        idx_opt.destroy_some()
    }

    fun key(info: &Info): Key {
        Key {
            t: info.asset_type,
            st: info.share_type,
        }
    }

    public fun add<T, ST>(self: &mut DebtBag, shares: DebtShareBalance<ST>) {
        let asset_type = type_name::get<T>();
        let share_type = type_name::get<ST>();
        if (shares.value_x64() == 0) {
            shares.destroy_zero();
            return
        };
        let key = Key{ t: asset_type, st: share_type };

        let idx_opt = get_asset_idx_opt(self, &asset_type);
        if (idx_opt.is_some()) {
            let idx = idx_opt.destroy_some();
            let info = &mut self.infos[idx];
            assert!(info.share_type == share_type, EAssetShareTypeMismatch);

            info.amount = info.amount + shares.value_x64();
            debt::join(&mut self.bag[key], shares);
        } else {
            // ensure that the share type is unique
            let mut i = 0;
            let n = self.infos.length();
            while (i < n) {
                let info = &self.infos[i];
                assert!(info.share_type != share_type, EAssetShareTypeMismatch);
                i = i + 1;
            };

            let info = Info {
                asset_type,
                share_type,
                amount: shares.value_x64(),
            };
            self.infos.push_back(info);

            bag::add(&mut self.bag, key, shares);
        };
    }

    public fun take_amt<ST>(self: &mut DebtBag, amount: u128): DebtShareBalance<ST> {
        if (amount == 0) {
            return debt::zero()
        };
        let type_st = type_name::get<ST>();

        let idx = get_share_idx(self, &type_st);
        let info = &mut self.infos[idx];
        assert!(amount <= info.amount, ENotEnough);

        let key = key(info);
        let shares = debt::split_x64(&mut self.bag[key], amount);
        info.amount = info.amount - amount;

        if (info.amount == 0) {
            let Info { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
            let zero = self.bag.remove(key);
            debt::destroy_zero<ST>(zero);
        };

        shares
    }

    public fun take_all<ST>(self: &mut DebtBag): DebtShareBalance<ST> {
        let type_st = type_name::get<ST>();

        let idx_opt = get_share_idx_opt(self, &type_st);
        if (idx_opt.is_none()) {
            return debt::zero()
        };
        let idx = idx_opt.destroy_some();

        let key = key(&self.infos[idx]);
        let Info { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
        let shares = self.bag.remove(key);

        shares
    }

    public fun get_share_amount_by_asset_type<T>(self: &DebtBag): u128 {
        let asset_type = type_name::get<T>();
        let idx_opt = get_asset_idx_opt(self, &asset_type);
        if (idx_opt.is_none()) {
            return 0
        } else {
            let idx = idx_opt.destroy_some();
            let info = &self.infos[idx];
            info.amount
        }
    }

    public fun get_share_amount_by_share_type<ST>(debt_bag: &DebtBag): u128 {
        let share_type = type_name::get<ST>();
        let idx_opt = get_share_idx_opt(debt_bag, &share_type);
        if (idx_opt.is_none()) {
            return 0
        } else {
            let idx = idx_opt.destroy_some();
            let info = &debt_bag.infos[idx];
            info.amount
        }
    }

    public fun get_share_type_for_asset<T>(self: &DebtBag): TypeName {
        let asset_type = type_name::get<T>();
        let idx_opt = get_asset_idx_opt(self, &asset_type);
        assert!(idx_opt.is_some(), ETypeDoesNotExist);
        let idx = idx_opt.destroy_some();
        let info = &self.infos[idx];
        info.share_type
    }
}